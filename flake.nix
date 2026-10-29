{
  description = "rtkt's overlay";
  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    pre-commit-hooks,
  }: let
    system = "x86_64-linux";
  in {
    checks.pre-commit-check = pre-commit-hooks.lib.x86_64-linux.run {
      src = ./.;
      hooks.alejandra.enable = true;
    };
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    overlays.default = final: prev: let
      localPkgs = import ./default.nix {pkgs = final;};
    in {
      inherit (localPkgs) samba-for-ps2 tcpflow n8n oplpctools nginx-dns anytype cutelyst cutelee virtlyst hpwnr;
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
      vivaldi-plasma6 = prev.vivaldi.overrideAttrs (oldAttrs: {
        dontWrapQtApps = false;
        dontPatchELF = true;
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [nixpkgs.legacyPackages.${system}.kdePackages.wrapQtAppsHook];
      });
      virt-manager-kde = prev.virt-manager.overrideAttrs (oldAttrs: {
        postInstall =
          oldAttrs.postInstall
          + ''
            substituteInPlace "$out/share/applications/virt-manager.desktop" --replace-fail "Exec=virt-manager" \
            "Exec=${nixpkgs.legacyPackages.${system}.coreutils}/bin/env SSH_ASKPASS=${nixpkgs.legacyPackages.${system}.kdePackages.ksshaskpass}/bin/ksshaskpass virt-manager"
          '';
      });
      cataclysm-dda-git =
        (prev.cataclysm-dda-git.overrideAttrs (previousAttrs: {
          debug = false;
        })).override {
          version = "2026-03-27";
          rev = "fa50e08c613dab24b385fc8bab092f7b83df9a6b";
          sha256 = "sha256-rl7K6h/L+khSnQrITSChuG35wnZvEK3EF9wNWeBXuPQ=";
          # patches = [
          #   ./cdda.patch
          # ];
        };
      libvirt-selinux = prev.libvirt.overrideAttrs (old: {
        buildInputs = old.buildInputs ++ [nixpkgs.legacyPackages.${system}.libselinux];
        mesonFlags = old.mesonFlags ++ ["-Dselinux=enabled" "-Dsecdriver_selinux=enabled"];
      });
    };
    nixosModules = {
      n8n = import ./modules/n8n;
      ntfy = import ./modules/ntfy;
      samba-for-ps2 = import ./modules/samba-for-ps2;
      sshguard-custom = import ./modules/sshguard-custom;
      nginx-dns = import ./modules/nginx-dns;
      virtlyst = import ./modules/virtlyst;
      hirovpn-updater = import ./modules/hirovpn-updater;
    };

    packages.${system} = import ./default.nix {
      pkgs = import nixpkgs {
        inherit system;
      };
    };
    devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
      inherit (self.checks.pre-commit-check) shellHook;
      inherit nixpkgs;
      buildInputs = self.checks.pre-commit-check.enabledPackages;
      nativeBuildInputs = with nixpkgs.legacyPackages.${system}; [
        cmake
        python3Packages.python
        wafHook
        pkg-config
        bison
        flex
        perl
        perl.pkgs.ParseYapp
        perl.pkgs.JSON
        libxslt
        buildPackages.stdenv.cc
        docbook_xsl
        docbook_xml_dtd_45
        rpcsvc-proto
      ];
    };
  };
}
