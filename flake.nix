{
  description = "rtkt's overlay";
  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
    # lib-aggregate.url = "github:nix-community/lib-aggregate";};
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        self.overlays.default
      ];
      config = {allowUnfree = true;};
    };
  in {
    overlays.default = final: prev: rec {
      samba-for-ps2 = final.callPackage ./pkgs/samba-for-ps2 {};
    };
    packages.x86_64-linux = pkgs;
  };
}
