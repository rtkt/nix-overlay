{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.sing-box.hirovpnUpdater;
  inherit (lib) mkEnableOption mkIf mkOption types;

  stateDir = "/var/lib/sing-box";
  runtimeDir = "/run/sing-box";
  stateFile = "${stateDir}/hiro.json";
  runtimeFile = "${runtimeDir}/90-hiro.json";

  filter = ./filter.jq;
  hpwnr = lib.getExe cfg.package;
  jq = lib.getExe pkgs.jq;
  singBox = lib.getExe config.services.sing-box.package;

  # This script is invoked by the timer and, if needed, as a bootstrapping
  # step on sing-box startup.  It never stores subscription data in /nix/store.
  updateScript = pkgs.writeShellScript "update-hirovpn" ''
    set -euo pipefail
    umask 077

    state_dir=${lib.escapeShellArg stateDir}
    key_file=${lib.escapeShellArg cfg.happKeyFile}
    dest=${lib.escapeShellArg stateFile}

    # Avoid simultaneous timer + bootstrap updates.
    exec 9>"$state_dir/.hiro.lock"
    ${lib.getExe' pkgs.util-linux "flock"} -x 9

    url=$(${lib.getExe' pkgs.coreutils "cat"} "$key_file")
    if [ -z "$url" ]; then
      echo "HiroVPN: the subscription file is empty" >&2
      exit 1
    fi

    tmp=$(${lib.getExe' pkgs.coreutils "mktemp"} "$state_dir/.hiro.XXXXXXXX.json")
    trap 'rm -f "$tmp"' EXIT

    # Explicit `fetch` also handles happ://add/... wrappers, not only HTTPS.
    ${hpwnr} "$url" fetch sb | ${jq} -e -f ${filter} > "$tmp"
    if [ ! -s "$tmp" ]; then
      echo "HiroVPN: empty filtered configuration" >&2
      exit 1
    fi

    # Validate against the base NixOS configuration when it is available.
    # On the first boot /run/sing-box/config.json might not exist yet.
    if [ -f ${runtimeDir}/config.json ]; then
      ${singBox} check -D "$state_dir" -c ${runtimeDir}/config.json -c "$tmp"
    else
      ${singBox} check -D "$state_dir" -c "$tmp"
    fi

    if [ -f "$dest" ] && ${lib.getExe' pkgs.diffutils "cmp"} -s "$tmp" "$dest"; then
      echo "HiroVPN: no changes"
    else
      # Keep one rollback copy outside the runtime configuration directory.
      if [ -f "$dest" ]; then
        ${lib.getExe' pkgs.coreutils "cp"} -f -- "$dest" "$state_dir/hiro.previous.json"
      fi
      ${lib.getExe' pkgs.coreutils "mv"} -f -- "$tmp" "$dest"
      echo "HiroVPN: server list updated"
    fi
  '';

  reloadScript = pkgs.writeShellScript "reload-sing-box-if-active" ''
    set -eu
    if ${pkgs.systemd}/bin/systemctl is-active --quiet sing-box.service; then
      ${pkgs.systemd}/bin/systemctl reload sing-box.service
    fi
  '';
in {
  options.services.sing-box.hirovpnUpdater = {
    enable = mkEnableOption "periodic HiroVPN subscription updates for sing-box";

    onCalendar = mkOption {
      type = types.str;
      default = "hourly";
      example = "*-*-* 00/3:00:00";
      description = "systemd OnCalendar expression for subscription refreshes.";
    };

    happKeyFile = mkOption {
      type = types.str;
      example = lib.literalExpression "config.sops.secrets.hiroHappKey.path";
      description = ''
        Absolute path to a runtime-only secret file containing one complete
        HiroVPN subscription link (HTTPS or happ://add/...). Do not provide
        the subscription value itself: Nix strings end up in /nix/store.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.hpwnr;
      defaultText = lib.literalExpression "pkgs.hpwnr";
      description = "hpwnr package with the patch that always outputs to stdout.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.sing-box.enable;
        message = "services.sing-box.hirovpnUpdater requires services.sing-box.enable.";
      }
      {
        assertion = config.services.sing-box.settings != {};
        message = "services.sing-box.hirovpnUpdater requires services.sing-box.settings (runtime config dir).";
      }
      {
        assertion = lib.hasPrefix "/" cfg.happKeyFile;
        message = "services.sing-box.hirovpnUpdater.happKeyFile must be an absolute runtime path.";
      }
    ];

    # Don't set services.sing-box.settings.outbounds here.  Keep the existing
    # base config (inbounds, DNS, API, route.final = "proxy") in NixOS.
    # The script is a preStart hook; it does not override the sops-nix-aware
    # ExecStartPre already configured by the upstream sing-box module.
    systemd.services.sing-box.preStart = lib.mkAfter ''
      if [ ! -s ${stateFile} ]; then
        ${updateScript}
      fi
      ${lib.getExe' pkgs.coreutils "ln"} -sfn ${stateFile} ${runtimeFile}
    '';

    systemd.services.sing-box-hirovpn = {
      description = "Update HiroVPN sing-box outbounds";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        User = "sing-box";
        Group = "sing-box";
        StateDirectory = "sing-box";
        StateDirectoryMode = "0700";
        WorkingDirectory = stateDir;
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ExecStart = updateScript;
        ExecStartPost = "+${reloadScript}";
      };
    };

    systemd.timers.sing-box-hirovpn = {
      description = "Periodically update HiroVPN sing-box outbounds";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
        RandomizedDelaySec = "2m";
        Unit = "sing-box-hirovpn.service";
      };
    };
  };
}
