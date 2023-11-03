{pkgs ? import <nixpkgs> {}}: rec {
  samba-for-ps2 = pkgs.callPackage ./pkgs/samba-for-ps2 {};
  tcpflow = pkgs.callPackage ./pkgs/tcpflow {};
  n8n = pkgs.callPackage ./pkgs/n8n {};
  oplpctools = pkgs.callPackage ./pkgs/oplpctools {};
  nginx-dns = pkgs.callPackage ./pkgs/nginx-dns {};
  any-date-parser = pkgs.callPackage ./pkgs/any-date-parser {};
}
