self: super:
{
  samba-for-ps2 = super.callPackage ./4.x.nix {
    lib = super.lib;
    gcc10Stdenv = super.gcc10Stdenv;
    buildPackages = super.buildPackages;
    fetchurl = super.fetchurl;
    wafHook = super.wafHook;
    pkg-config = super.pkg-config;
    bison = super.bison;
    flex = super.flex;
    perl = super.perl;
    libxslt = super.libxslt;
    heimdal = super.heimdal;
    docbook_xsl = super.docbook_xsl;
    docbook_xml_dtd_45 = super.docbook_xml_dtd_45;
    readline = super.readline;
    popt = super.popt;
    dbus = super.dbus;
    libbsd = super.libbsd;
    zlib = super.zlib;
    liburing = super.liburing;
    gnutls = super.gnutls;
    libunwind = super.libunwind;
    systemd = super.systemd;
    jansson = super.jansson;
    libtasn1 = super.libtasn1;
    tdb = super.tdb;
    cmocka = super.cmocka;
    rpcsvc-proto = super.rpcsvc-proto;
    python3Packages = super.python3Packages;
    nixosTests = super.nixosTests;
  };
}