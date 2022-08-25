self: super:
{
  ntfy-full = super.callPackage ./ntfy-full.nix {
    lib = super.lib;
    bash = super.bash;
    gnumake = super.gnumake;
    buildGoModule = super.buildGoModule;
    fetchgit = super.fetchgit;
    npm = super.nodePackages.npm;
    git = super.git;
    nodejs = super.nodejs;
  };
}
