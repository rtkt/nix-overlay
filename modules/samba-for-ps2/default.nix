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
  genCommands = devices: concatStrings (forEach devices (device: "iptables -A INPUT -p tcp --destination-port ${cfg.port} -m mac --mac-source ${device} -j ACCEPT\n"));
  samba-for-ps2 = cfg.package;
  genFilesSettings = mode: {
    d = {
      user = cfg.user;
      group = cfg.group;
      mode = "${builtins.toString mode}";
    };
    Z = {
      user = cfg.user;
      group = cfg.group;
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
      allowedDevices = mkOption {
        type = types.nullOr types.listOf types.str;
        description = "MAC addresses of the allowed devices";
        default = null;
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
            "/var/log/samba" = genFilesSettings 0700;
            "/var/cache/samba-for-ps2" = genFilesSettings 0700;
            "/var/lib/samba-for-ps2" = genFilesSettings 0700;
            "/var/lib/samba-for-ps2/private" = genFilesSettings 0700;
            "/run/samba-for-ps2" = genFilesSettings 0700;
          };
        };
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
      (mkIf (cfg.openFirewall && cfg.allowedDevices == null) {
        networking.firewall.allowedTCPPorts = [cfg.port];
      })
      (mkIf (cfg.openFirewall && cfg.allowedDevices != null) {
        networking.firewall.extraCommands = genCommands cfg.allowedDevices;
      })
    ];
}
