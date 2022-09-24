self: super:

{
  tcpflow = super.callPackage ./tcpflow.nix {
    stdenv = super.stdenv;
    lib = super.lib;
    fetchFromGitHub = super.fetchFromGitHub;
    automake = super.automake;
    autoconf = super.autoconf;
  };
}
