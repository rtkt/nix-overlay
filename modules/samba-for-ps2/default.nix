{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  smbToString = x:
    if builtins.typeOf x == "bool"
    then boolToString x
    else toString x;
  cfg = config.services.samba-for-ps2;
  samba-for-ps2 = cfg.package;
  shareConfig = name: let
    share = getAttr name cfg.shares;
  in
    "[${name}]\n"
    + (smbToString (
      map
      (key: "${key} = ${smbToString (getAttr key share)}\n")
      (attrNames share)
    ));
  configFile = pkgs.writeText "smb.conf" ''
    [global]
    ${cfg.globalConfig}

    ${smbToString (map shareConfig (attrNames cfg.shares))}
  '';
  daemonService = appName: args: {
    description = "Minimal Samba Service Daemon for Playstation 2 ${appName}";
    requiredBy = ["samba-for-ps2.target"];
    partOf = ["samba-for-ps2.target"];

    environment = {
      LOCALE_ARCHIVE = "/run/current-system/sw/lib/locale/locale-archive";
    };
    serviceConfig = {
      ExecStart = "${pkgs.samba-for-ps2}/sbin/${appName} --foreground --no-process-group ${args}";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
      LimitNOFILE = 16384;
      PIDFile = "/run/${appName}.pid";
      Type = "exec";
      User = "${cfg.user}";
    };
    unitConfig.RequiresMountsFor = "/var/lib/samba-for-ps2";

    restartTriggers = [configFile];
  };
in {
  options = {
    services.samba-for-ps2 = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      package = mkOption {
        type = types.package;
        default = pkgs.samba-for-ps2;
        defaultText = "pkgs.samba-for-ps2";
      };
      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to automatically open the necessary ports in the firewall";
      };
      restrictAccess = mkOption {
        type = types.bool;
        default = false;
        description = "Restrict access to network port only specific device?";
      };
      allowedDevice = mkOption {
        type = types.str;
        description = "MAC address of the allowed device";
      };
      port = mkOption {
        type = types.str;
        description = "Which port to use for this service?";
      };
      user = mkOption {
        type = types.str;
        description = "User which runs the Samba daemon";
        default = "samba-for-ps2";
      };
      group = mkOption {
        type = types.str;
        description = "Group under which samba-for-ps2 runs";
        default = "${cfg.user}";
      };
      globalConfig = mkOption {
        type = types.lines;
        description = "Global samba config";
        default = ''
          workgroup = WORKGROUP
          map to guest = Bad Password
          guest account = nobody
          socket options = TCP_NODELAY TCP_KEEPIDLE=20 IPTOS_LOWDELAY SO_KEEPALIVE
          lanman auth = no
          server min protocol = NT1
          server signing = disabled
          lm announce = no
          smb ports = ${cfg.port}
        '';
      };
      shares = mkOption {
        default = {};
        type = types.attrsOf (types.attrsOf types.unspecified);
      };
    };
  };
  config =
    mkMerge
    [
      {
        environment.etc."samba-for-ps2/smb.conf".source = mkOptionDefault (
          if cfg.enable
          then configFile
          else pkgs.writeText "smb-dummy.conf" "# Samba is disabled."
        );
      }
      (mkIf cfg.enable {
        system.activationScripts.set-permissions-for-smbd = ''
          chown -R ${cfg.user}:${cfg.group} /var/lock/samba-for-ps2
          chown -R ${cfg.user}:${cfg.group} /var/log/samba-for-ps2
          chown -R ${cfg.user}:${cfg.group} /var/cache/samba-for-ps2
          chown -R ${cfg.user}:${cfg.group} /var/run/samba-for-ps2
          chown -R ${cfg.user}:${cfg.group} /var/lib/samba-for-ps2
        '';
        systemd = {
          targets.samba-for-ps2 = {
            description = "Minimal Samba Server for Playstation 2";
            after = ["network.target"];
            wantedBy = ["multi-user.target"];
          };
          services = {
            samba-for-ps2-smbd = daemonService "smbd" "";
          };
          tmpfiles.rules = [
            "d /var/lock/samba-for-ps2 1700 ${cfg.user} ${cfg.group} - -"
            "d /var/log/samba-for-ps2 1700 ${cfg.user} ${cfg.group} - -"
            "d /var/cache/samba-for-ps2 1700 ${cfg.user} ${cfg.group} - -"
            "d /var/lib/samba-for-ps2/private 1700 ${cfg.user} ${cfg.group} - -"
          ];
        };
        networking.firewall.extraCommands = mkIf cfg.openFirewall ''
          iptables -A INPUT -p tcp --destination-port ${cfg.port} ${
            if cfg.restrictAccess
            then "-m mac --mac-source ${cfg.allowedDevice}"
            else ""
          } -j ACCEPT
        '';
        users = {
          users."${cfg.user}" = {
            isSystemUser = true;
            description = "Samba-for-ps2 service account";
            home = "/var/lib/samba-for-ps2";
            createHome = true;
            shell = "${pkgs.shadow}/bin/nologin";
            group = "${cfg.group}";
          };
          groups."${cfg.group}" = {};
        };
      })
    ];
}
