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
      inherit (localPkgs) samba-for-ps2 tcpflow n8n oplpctools nginx-dns;
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
      n8n = import ./modules/n8n;
      ntfy = import ./modules/ntfy;
      samba-for-ps2 = import ./modules/samba-for-ps2;
      sshguard-custom = import ./modules/sshguard-custom;
      nginx-dns = import ./modules/nginx-dns;
    };

    packages.${system} = import ./default.nix {
      pkgs = import nixpkgs {
        inherit system;
      };
    };
    devShells.${system}.default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix {};
  };
}
