{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.virtlyst;
  ini = pkgs.writeText "virtlyst.ini" ''
    [wsgi]
    master = true
    threads = auto
    http-socket = :${builtins.toString cfg.port}
    application = ${pkgs.virtlyst}/lib/libVirtlyst.so
    chdir2 = ${pkgs.virtlyst}
    static-map = /static=root/static

    [Cutelyst]
    production = true
    DatabasePath = ${builtins.toString cfg.dataDir}/virtlyst.sqlite
    TemplatePath = ${pkgs.virtlyst}/root/src

    [Rules]
    cutelyst.* = true
    virtlyst.* = true
  '';
in {
  options = {
    services.virtlyst = {
      enable = lib.mkEnableOption "virtlyst";
      port = lib.mkOption {
        default = 3000;
        type = lib.types.int;
        description = "Port number to use";
      };
      runAsRoot = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = "Run as root or not?";
      };
      user = lib.mkOption {
        default = "virtlyst";
        type = lib.types.str;
        description = "Username that virtlyst will use";
      };
      group = lib.mkOption {
        default = "virtlyst";
        type = lib.types.str;
        description = "Group that virtlyst will use";
      };
      dataDir = lib.mkOption {
        default = /var/lib;
        type = lib.types.path;
        description = "Path to data directory";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.virtlyst = {
      description = "WebUI to control libvirt";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        User =
          if cfg.runAsRoot
          then "root"
          else cfg.user;
        Group =
          if cfg.runAsRoot
          then "root"
          else cfg.group;
        Type = "simple";
        ExecStart = "${pkgs.cutelyst}/bin/cutelystd4-qt6 --application ${pkgs.virtlyst}/lib/libVirtlyst.so --chdir2 ${pkgs.virtlyst} --ini ${ini} --static-map /static=root/static --http-socket localhost:${builtins.toString cfg.port} --master";
      };
    };
    users = lib.mkIf (! cfg.runAsRoot) {
      users."${cfg.user}" = {
        isSystemUser = true;
        group = cfg.group;
      };
      groups."${cfg.group}" = {};
    };
  };
}
