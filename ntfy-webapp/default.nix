self: super:
{
  ntfy-webapp = super.callPackage ./package.nix {
    pkgs = super.pkgs;
    lib = super.lib;
    npm = super.nodePackages.npm;
    nodejs-16_x = super.nodejs-16_x;
    stdenv = super.stdenv;
  };
}
