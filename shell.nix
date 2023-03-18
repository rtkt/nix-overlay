{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.cmake
    pkgs.python3Packages.python
    pkgs.wafHook
    pkgs.pkg-config
    pkgs.bison
    pkgs.flex
    pkgs.perl
    pkgs.perl.pkgs.ParseYapp
    pkgs.perl.pkgs.JSON
    pkgs.libxslt
    pkgs.buildPackages.stdenv.cc
    pkgs.docbook_xsl
    pkgs.docbook_xml_dtd_45
    pkgs.rpcsvc-proto
  ];
}
