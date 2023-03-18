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
      tor-browser-bundle-bin = prev.tor-browser-bundle-bin.overrideAttrs (finalAttrs: previousAttrs: {
        src = prev.fetchurl {
          url = "https://tor.calyxinstitute.org/dist/torbrowser/11.5.8/tor-browser-linux64-11.5.8_en-US.tar.xz";
          sha256 = "sha256-/KK9oTijk5dEziAwp5966NaM2V4k1mtBjTJq88Ct7N0=";
        };
      });
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
    };
    nixosModules = {
      samba-for-ps2 = import ./modules/samba-for-ps2;
    };

    packages.${system} = import ./default.nix {
      pkgs = import nixpkgs {
        inherit system;
        # config.allowUnfree = true;
      };
    };
    devShells.${system}.default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix {};
  };
}
