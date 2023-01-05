{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./client.nix
    ./server.nix
  ];
}
