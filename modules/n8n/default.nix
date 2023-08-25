{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.n8n-custom;
in {
  options.services.n8n-custom = {
    enable = mkEnableOption "n8n custom server";
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open ports in the firewall for the n8n web interface.";
    };
    settings = mkOption {
      type = with types; attrsOf (either str (listOf str));
      default = {};
      apply = mapAttrs (n: v:
        if isList v
        then concatStrinsSep ":" v
        else v);
      description = "Set of configurational environment variables";
    };
    quota = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "CPU quota in percents";
    };
    memorymax = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Maximum amount of RAM. See man systemd.resource-control";
    };
    user = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of the N8N service user. If it's not specified then systemd will create dynamic user";
    };
    group = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of the N8N service group. If it's not specified then the name of the user will be used";
    };
  };

  config = mkIf cfg.enable {
    users.users = mkIf (builtins.isString cfg.user) {
      "${cfg.user}" = {
        isSystemUser = true;
        home = "/var/lib/n8n";
        group = "${
          if (builtins.isString cfg.group)
          then cfg.group
          else cfg.user
        }";
        shell = "${pkgs.shadow}/bin/nologin";
      };
    };
    users.groups = mkIf (builtins.isString cfg.user) {
      "${
        if (builtins.isString cfg.group)
        then cfg.group
        else cfg.user
      }" = {};
    };
    systemd.services.n8n-custom = {
      description = "N8N service";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment = cfg.settings;
      path = [pkgs.nodejs_20 pkgs.n8n];
      serviceConfig = mkMerge [
        {
          Type = "simple";
          ExecStart = "${pkgs.n8n}/bin/n8n";
          Restart = "on-failure";
          StateDirectory = "n8n";
          CPUSchedulingPolicy = "batch";

          NoNewPrivileges = "yes";
          PrivateTmp = "yes";
          PrivateDevices = "yes";
          DevicePolicy = "closed";
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ProtectControlGroups = "yes";
          ProtectKernelModules = "yes";
          ProtectKernelTunables = "yes";
          RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
          RestrictNamespaces = "yes";
          RestrictRealtime = "yes";
          RestrictSUIDSGID = "yes";
          MemoryDenyWriteExecute = "no";
          LockPersonality = "yes";
        }
        (
          mkIf (builtins.isInt cfg.quota) {
            CPUQuota = "${builtins.toString cfg.quota}%";
          }
        )
        (
          mkIf (builtins.isString cfg.memorymax) {
            MemoryMax = "${cfg.memorymax}";
          }
        )
        (
          if (builtins.isString cfg.user)
          then {
            User = "${cfg.user}";
          }
          else {
            DynamicUser = "true";
          }
        )
      ];
    };
  };
}
