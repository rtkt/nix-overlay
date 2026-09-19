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
  genFilesSettings = mode: {
    d = {
      user = "root";
      group = "root";
      mode = "${builtins.toString mode}";
    };
    Z = {
      user = "root";
      group = "root";
      mode = "${builtins.toString mode}";
    };
  };
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
      ExecStart = "${cfg.package}/sbin/${appName} --foreground --no-process-group ${args}";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      LimitNOFILE = 16384;
      PIDFile = "/run/${appName}.pid";
      Type = "exec";
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
      allowedDevices = mkOption {
        type = types.listOf types.str;
        description = "MAC addresses of the allowed devices";
        default = [];
      };
      globalConfig = mkOption {
        type = types.lines;
        description = "Global samba config";
      };
      port = mkOption {
        type = types.int;
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
        systemd = {
          targets.samba-for-ps2 = {
            description = "Minimal Samba Server for Playstation 2";
            after = ["network.target"];
            wantedBy = ["multi-user.target"];
          };
          services = {
            samba-for-ps2-smbd = daemonService "smbd" "";
          };
          tmpfiles.settings."10-samba-for-ps2" = {
            "/var/lock/samba-for-ps2" = genFilesSettings 0755;
            "/var/log/samba-for-ps2" = genFilesSettings 0700;
            "/var/cache/samba-for-ps2" = genFilesSettings 0700;
            "/var/lib/samba-for-ps2" = genFilesSettings 0700;
            "/var/lib/samba-for-ps2/private" = genFilesSettings 0700;
            "/run/samba-for-ps2" = genFilesSettings 0700;
          };
        };
      })
      (mkIf (cfg.openFirewall && !cfg.restrictAccess) {
        networking.firewall.allowedTCPPorts = [cfg.port];
      })
      (mkIf (cfg.openFirewall && cfg.restrictAccess) {
        assertions = [
          {
            assertion = cfg.allowedDevices != [];
            message = "services.samba-for-ps2: restrictAccess is enabled but allowedDevices is empty";
          }
        ];
        networking.firewall.extraInputRules = ''
          ether saddr { ${concatStringsSep ", " cfg.allowedDevices} } tcp dport ${toString cfg.port} accept
        '';
      })
    ];
}
