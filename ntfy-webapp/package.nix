{ pkgs, nodejs-16_x, stdenv, lib, npm }:


let
  nodePackages = import ./node-composition.nix {
    inherit pkgs;
    inherit (stdenv.hostPlatform) system;
  };
in
nodePackages.ntfy.override {
  dontNpmInstall = true;
  preInstall = ''
    ${npm}/bin/npm run build
  '';
}
