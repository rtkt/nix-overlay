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
      tcpflow = final.callPackage ./pkgs/tcpflow {};

      tor-browser-bundle-bin = prev.tor-browser-bundle-bin.overrideAttrs (finalAttrs: previousAttrs: {
        version = "11.5.2";
        lang = "en-US";
        src = prev.fetchurl {
          url = "https://tor.calyxinstitute.org/dist/torbrowser/11.5.2/tor-browser-linux64-11.5.2_en-US.tar.xz";
          sha256 = "sha256-kM3OOFTpEU7nIyqqdGcqLZ86QLb6isM5cfWG7jo891o=";
        };
      });
    };
    packages.x86_64-linux = pkgs;
  };
}
