{
  description = "Flakiefied collection of Nix overlays";

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }: {
    overlay = import ./default.nix;
  };
}
