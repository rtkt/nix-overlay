{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nginx-dns;
in {
  options.services.nginx-dns = {
    enable = mkEnableOption "DNS proxying";
    domain = mkOption {
      type = types.str;
      description = "Domain name to run on";
    };
    port = mkOption {
      type = types.int;
      description = "Internal upstream port";
      default = 8053;
    };
    loopAddr = mkOption {
      type = types.str;
      description = "Name of the internal upstream loop";
      default = "dohloop";
    };
    upstream = mkOption {
      type = types.str;
      description = "Upstream address and port";
      example = "127.0.0.1:53";
    };
  };
  config = mkIf cfg.enable {
    services.nginx = {
      additionalModules = [
        pkgs.nginxModules.njs
      ];
      streamConfig = ''
        js_import ${pkgs.nginx-dns}/dns.js;

        upstream dns {
          zone dns 64k;
          server ${cfg.upstream};
        }

        server {
          listen 127.0.0.1:${builtins.toString cfg.port};
          js_filter dns.filter_doh_request;
          proxy_pass dns;
        }
      '';
      upstreams."${cfg.loopAddr}" = {
        servers."127.0.0.1:${builtins.toString cfg.port}" = {};
        extraConfig = ''
          zone ${cfg.loopAddr} 64k;
        '';
      };
      virtualHosts."${cfg.domain}".locations."/dns-query" = {
        proxyPass = "http://${cfg.loopAddr}";
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_set_header Connection "";
        '';
      };
    };
  };
}
