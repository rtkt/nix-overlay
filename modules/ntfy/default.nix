{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.ntfy;
in {
  options.services.ntfy = {
    enable = mkEnableOption "ntfy server";
    behindProxy = mkEnableOption "reading X-Forwarded-For HTTP field";
    debug = mkEnableOption "debug logging";
    authFile = mkOption {
      type = types.str;
      default = "authentication.db";
      description = "Name of the authentication file";
    };
    attachments = {
      enable = mkEnableOption "attachments support";
      cacheDir = mkOption {
        type = types.str;
        description = "Name of the directory to store cached attachments on disk (/var/cache is added automatically)";
        default = "ntfy";
      };
      expiryDuration = mkOption {
        type = types.str;
        description = "duration after which uploaded attachments will be deleted (e.g. 3h, 20h) (default: 24h)";
        default = "24h";
      };
      fileSizeLimit = mkOption {
        type = types.str;
        description = "per-file attachment size limit (e.g. 300k, 2M, 100M) (default: 100M)";
        default = "100M";
      };
      totalSizeLimit = mkOption {
        type = types.str;
        description = "limit of the on-disk attachment cache";
        default = "1G";
      };
      baseURL = mkOption {
        type = types.str;
        description = "externally visible base URL for this host (e.g. https://ntfy.sh)";
      };
    };
    listenHTTP = mkOption {
      type = types.str;
      description = "IP address:port to listen to (for unencrypted HTTP traffic)";
      default =
        if cfg.behindProxy
        then "localhost:9999"
        else ":80";
    };
    stateDirectory = mkOption {
      type = types.str;
      description = "Name of the state directory (/var/lib is prepended automatically)";
      default = "ntfy";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.ntfy = {
      description = "ntfy server";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.ntfy-sh];
      environment = {
        NTFY_LOG_LEVEL =
          if cfg.debug
          then "DEBUG"
          else "WARN";
        NTFY_AUTH_FILE = "/var/lib/${cfg.stateDirectory}/${cfg.authFile}";
      };
      serviceConfig = {
        ExecStart = ''
          ${pkgs.ntfy-sh}/bin/ntfy serve \
            ${
            if cfg.behindProxy
            then "-P"
            else ""
          } \
            -l '${cfg.listenHTTP}' \
            ${
            if cfg.attachments.enable
            then "--attachment-cache-dir /var/cache/${cfg.attachments.cacheDir} -X ${cfg.attachments.expiryDuration} -B ${cfg.attachments.baseURL} -Y ${cfg.attachments.fileSizeLimit} -A ${cfg.attachments.totalSizeLimit} "
            else " "
          }
        '';
        DynamicUser = true;
        CacheDirectory = "${cfg.attachments.cacheDir}";
        StateDirectory = "${cfg.stateDirectory}";
      };
    };
  };
}
