{ nixpkgs, ... }:

{
  nixpkgs.overlays = [
    (import ./google-authenticator-no-qrencode)
    (import ./ntfy-webapp)
    # (import ./ntfy-full)
    (import ./samba-for-ps2)
    (import ./tcpflow)
    (import ./tor-browser-bundle-bin)
  ];
}
