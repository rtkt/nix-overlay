{pkgs ? import <nixpkgs> {}}: rec {
  anytype = pkgs.callPackage ./pkgs/anytype {};
  samba-for-ps2 = pkgs.callPackage ./pkgs/samba-for-ps2 {};
  tcpflow = pkgs.callPackage ./pkgs/tcpflow {};
  n8n = pkgs.callPackage ./pkgs/n8n {};
  oplpctools = pkgs.callPackage ./pkgs/oplpctools {};
  nginx-dns = pkgs.callPackage ./pkgs/nginx-dns {};
  cutelyst = pkgs.callPackage ./pkgs/cutelyst {};
}
