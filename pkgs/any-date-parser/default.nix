{
  pkgs,
  stdenv,
}: let
  nodePackages = import ./node-composition.nix {
    inherit pkgs;
    inherit (stdenv.hostPlatform) system;
  };
in
  nodePackages.any-date-parser.override {}
