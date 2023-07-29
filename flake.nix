{
  description = "rtkt's overlay";
  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
  in {
    overlays.default = final: prev: let
      localPkgs = import ./default.nix {pkgs = final;};
    in {
      inherit (localPkgs) samba-for-ps2 tcpflow n8n oplpctools;
      google-authenticator =
        (prev.google-authenticator.overrideAttrs (finalAttrs: previousAttrs: {
          preConfigure = null;
        }))
        .override {
          qrencode = null;
        };
      gnupg-minimal = prev.gnupg.override {
        enableMinimal = true;
      };
      node2nix = prev.node2nix.overrideAttrs (finalAttrs: previousAttrs: {
        src = prev.fetchFromGitHub {
          owner = "rtkt";
          repo = "node2nix";
          rev = "ea8ebcdacf496c3d35d8eb2b115d10c8f01d8823";
          sha256 = "sha256-DCdmlyzta2gmqmXjV5NuQj5BgimifBFKIU7rk1OS4pw=";
        };
      });
    };
    nixosModules = {
      n8n = import ./modules/n8n;
      ntfy = import ./modules/ntfy;
      samba-for-ps2 = import ./modules/samba-for-ps2;
    };

    packages.${system} = import ./default.nix {
      pkgs = import nixpkgs {
        inherit system;
      };
    };
    devShells.${system}.default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix {};
  };
}
