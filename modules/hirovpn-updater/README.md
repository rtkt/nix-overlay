# HiroVPN updater for NixOS sing-box

Copy `default.nix` and `filter.jq` into `desktop/sing-box/updater/` and import `./updater` in your NixOS module.

Example using sops-nix (the secret must contain the complete subscription link, without quotes):

```nix
{ config, ... }:
{
  imports = [ ./updater ];

  sops.secrets.hiroHappKey = {
    sopsFile = ./hirovpn.yaml;
    key = "happKey";
    owner = "sing-box";
    group = "sing-box";
    mode = "0400";
  };

  services.sing-box.hirovpnUpdater = {
    enable = true;
    onCalendar = "*-*-* 00/3:00:00";
    happKeyFile = config.sops.secrets.hiroHappKey.path;
  };
}
```

The service stores full decrypted VLESS profiles under `/var/lib/sing-box/hiro.json` (`0600`), links them into `/run/sing-box/90-hiro.json` at sing-box startup, and reloads the daemon when the timer completes successfully. On first startup, it fetches an initial subscription if no cached file is available. On failed updates the previous file remains intact. Successful replacements retain a rollback copy as `/var/lib/sing-box/hiro.previous.json`.

The base sing-box config must *not* include the old VLESS nodes or selector/urltest named `proxy` and `auto`. It may keep `route.final = "proxy"`.

Commands:

```sh
systemctl list-timers sing-box-hirovpn.timer
sudo systemctl start sing-box-hirovpn.service
journalctl -u sing-box-hirovpn.service -n 60 --no-pager
```

Requires hpwnr patched to print large output to stdout, and a complete, reachable HiroVPN subscription URL in sops. The subscription is exposed in `hpwnr` process argv briefly (current hpwnr CLI accepts its URL only as an argument). No Rust/NixOS build has been run in this environment.
