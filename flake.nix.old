{
  description = "Flakiefied collection of Nix overlays";

  inputs = {
    nixpkgs = {url = "flake:nixpkgs/nixos-unstable";};
    lib-aggregate = {url = "github:nix-community/lib-aggregate";};
  };
  outputs = inputs: let
    inherit (inputs.lib-aggregate) lib;
    inherit (inputs) self;

    ownOverlay = (
      final: prev: let
        ownPkgs = rec {
          samba-for-ps2 = prev.callPackage ./samba-for-ps2;
          # tcpflow = prev.callPackage ./tcpflow;
        };
      in (ownPkgs // {inherit ownPkgs;})
    );
  in
    lib.flake-utils.eachSystem ["x86_64-linux"]
    (
      system: let
        pkgsFor = pkgs: overlays:
          import pkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };
        pkgs_ = lib.genAttrs (builtins.attrNames inputs) (inp: pkgsFor inputs."${inp}" []);
        opkgs_ = overlays: lib.genAttrs (builtins.attrNames inputs) (inp: pkgsFor inputs."${inp}" overlays);
        ownpkgs = (opkgs_ [self.overlays.default]).nixpkgs;
      in {
        devShells.default = pkgs_.nixpkgs.mkShell {
          nativeBuildInputs =
            []
            ++ (with pkgs_.nixpkgs; [
              openssl
              zlib
              libpcap
              boost
              pkg-config
              libxslt
              heimdal
              docbook_xml_dtd_45
              docbook_xsl
              readline
              popt
              dbus
              libbsd
              liburing
              gnutls
              libunwind
              systemd
              jansson
              libtasn1
              tdb
              cmocka
              rpcsvc-proto
              nodejs-16_x
              nodePackages.npm
            ]);
        };
        packages = (
          ownpkgs.ownPkgs
          // {
            default =
              ownpkgs.linkFarmFromDrvs "nixpkgs-own-overlay"
              (builtins.attValues ownpkgs.ownPkgs);
          }
        );
      }
    )
    // {
      overlay = ownOverlay;
      overlays.default = ownOverlay;
    };
}
