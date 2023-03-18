{pkgs ? import <nixpkgs> {}}: rec {
  samba-for-ps2 = pkgs.callPackage ./pkgs/samba-for-ps2 {};
  tcpflow = pkgs.callPackage ./pkgs/tcpflow {};
  n8n = pkgs.callPackage ./pkgs/n8n {};
  oplpctools = pkgs.callPackage ./pkgs/oplpctools {};
}
