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
    path = mkOption {
      type = types.listOf;
      default = [];
    };
  };

  config = mkIf cfg.enable {
    systemd.services.n8n-custom = {
      description = "N8N service";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment = cfg.settings;
      path = [ pkgs.nodejs-18_x pkgs.n8n ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.n8n}/bin/n8n";
        Restart = "on-failure";
        StateDirectory = "n8n";

        NoNewPrivileges = "yes";
        PrivateTmp = "yes";
        PrivateDevices = "yes";
        DevicePolicy = "closed";
        DynamicUser = "true";
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
      };
    };
  };
}
