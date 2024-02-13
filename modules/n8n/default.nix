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
    port = mkOption {
      type = types.int;
      default = 9998;
      description = "N8N's network port";
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
    key = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "N8N's encryption key that is exported in N8N_ENCRYPTION_KEY environment variable. See https://docs.n8n.io/hosting/environment-variables/environment-variables/#deployment for more";
    };
    queue = mkOption {
      description = "N8N's queue execution mode settings";
      type = types.submodule {
        enable = mkEnableOption "queue execution mode";

        redis = mkOption {
          description = "Redis queue settings";
          type = types.submodule {
            host = mkOption {
              description = "Address of the host that runs Redis queue DB";
              default = "localhost";
              type = types.str;
            };
            port = mkOption {
              description = "Port of the Redis";
              type = types.int;
            };
            passwordFile = mkOption {
              description = "Path to the file with password for Redis";
              type = types.nullOr types.str;
              default = null;
            };
          };
        };
      };
    };
    smtp = mkOption {
      description = "SMTP settings. Enables user management";
      type = types.submodule {
        options = {
          enable = mkEnableOption "SMTP";

          host = mkOption {
            description = "Mail server address";
            type = types.str;
            example = "mail.google.com";
          };
          port = mkOption {
            description = "SMTP server port";
            default = null;
            type = types.nullOr types.int;
            example = 993;
          };
          sender = mkOption {
            description = "Sender name";
            type = types.str;
            example = "N8N";
          };
          user = mkOption {
            description = "SMTP username";
            default = null;
            type = types.nullOr types.str;
            example = "anon";
          };
          passwordFile = mkOption {
            description = "Path to the file with SMTP users' password";
            default = null;
            type = types.nullOr types.path;
            example = "/run/pass";
          };
          ssl = mkEnableOption "SSL for SMTP";
        };
      };
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
      environment = mkMerge [
        cfg.settings
        (
          mkIf cfg.smtp.enable (
            mkMerge [
              {
                N8N_EMAIL_MODE = "smtp";
                N8N_SMTP_HOST = "${cfg.smtp.host}";
                N8N_SMTP_SENDER = "${cfg.smtp.sender}";
              }
              (
                mkIf (builtins.isInt cfg.smtp.port) {
                  N8N_SMTP_PORT = "${builtins.toString cfg.smtp.port}";
                }
              )
              (
                mkIf (!cfg.smtp.ssl) {
                  N8N_SMTP_SSL = "false";
                }
              )
              (
                mkIf (cfg.queue.enable) {
                  EXECUTIONS_MODE = "queue";
                  QUEUE_BULL_REDIS_HOST = "${cfg.queue.redis.host}";
                  QUEUE_BULL_REDIS_PORT = "${builtins.toString cfg.queue.redis.port}";
                }
              )
            ]
          )
        )
        (
          mkIf (builtins.isInt cfg.port) {
            N8N_PORT = "${builtins.toString cfg.port}";
          }
        )
      ];
      path = [pkgs.nodejs_20 pkgs.n8n];
      script = ''
        ${optionalString (cfg.smtp.user != null && cfg.smtp.passwordFile != null) ''
          export N8N_SMTP_USER="${cfg.smtp.user}"
          export N8N_SMTP_PASS="$(cat ${cfg.smtp.passwordFile})"
        ''}

        ${optionalString (cfg.key != null) ''
          export N8N_ENCRYPTION_KEY="$(cat ${cfg.key})"
        ''}

        ${optionalString (cfg.queue.enable == true && cfg.queue.redis.passwordFile != null) ''
          export QUEUE_BULL_REDIS_PASSWORD="$(cat ${cfg.queue.redis.passwordFile})"
        ''}
        ${pkgs.n8n}/bin/n8n; \
        ${pkgs.n8n}/bin/n8n worker; \
        ${pkgs.n8n}/bin/n8n worker; \
        ${pkgs.n8n}/bin/n8n worker; \
        ${pkgs.n8n}/bin/n8n worker
      '';
      serviceConfig = mkMerge [
        {
          Type = "simple";
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
