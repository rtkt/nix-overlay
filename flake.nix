{
  description = "Flakiefied collection of Nix overlays";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = (import nixpkgs) {
      system = "x86_64-linux";
      overlays = [
        (import ./overlay.nix)
      ];
      config.allowUnfree = true;
    };
  in {
    overlays = {
      default = import ./overlay.nix;
    };
    packages."x86_64-linux" = pkgs;
  };
}
