{ lib, gcc10Stdenv
, buildPackages
, fetchurl
, wafHook
, pkg-config
, bison
, flex
, perl
, libxslt
, heimdal
, docbook_xsl
, docbook_xml_dtd_45
, readline
, popt
, dbus
, libbsd
, zlib
, liburing
, gnutls
, libunwind
, systemd
, jansson
, libtasn1
, tdb
, cmocka
, rpcsvc-proto
, python3Packages
, nixosTests
}:

with lib;

gcc10Stdenv.mkDerivation rec {
  pname = "samba-for-ps2";
  version = "4.15.5";

  src = fetchurl {
    url = "mirror://samba/pub/samba/stable/samba-${version}.tar.gz";
    sha256 = "sha256-aRFeM4MZN7pRUb4CR5QxR3Za7OZYunQ/RHQWcq1o0X8=";
  };

  outputs = [ "out" "dev" "man" ];

  patches = [
    ./4.x-no-persistent-install.patch
    ./patch-source3__libads__kerberos_keytab.c.patch
    ./4.x-no-persistent-install-dynconfig.patch
    ./4.x-fix-makeflags-parsing.patch
    ./build-find-pre-built-heimdal-build-tools-in-case-of-.patch
  ];

  nativeBuildInputs = [
    python3Packages.python
    wafHook
    pkg-config
    bison
    flex
    perl
    perl.pkgs.ParseYapp
    libxslt
    buildPackages.stdenv.cc
    heimdal
    docbook_xsl
    docbook_xml_dtd_45
    cmocka
    rpcsvc-proto
  ];

  buildInputs = [
    python3Packages.python
    python3Packages.wrapPython
    readline
    popt
    dbus
    jansson
    libbsd
    zlib
    libunwind
    gnutls
    libtasn1
    tdb
    liburing
    systemd
  ];

  wafPath = "buildtools/bin/waf";

  postPatch = ''
    # Removes absolute paths in scripts
    sed -i 's,/sbin/,,g' ctdb/config/functions

    # Fix the XML Catalog Paths
    sed -i "s,\(XML_CATALOG_FILES=\"\),\1$XML_CATALOG_FILES ,g" buildtools/wafsamba/wafsamba.py

    patchShebangs ./buildtools/bin
  '';

  preConfigure = ''
    export PKGCONFIG="$PKG_CONFIG"
  '';

  wafConfigureFlags = [
    "--with-static-modules=NONE"
    "--with-shared-modules=ALL"
    "--enable-fhs"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--with-configdir=/etc/samba-for-ps2"
    "--with-privatedir=/var/lib/samba-for-ps2/private"
    "--with-bind-dns-dir=/var/lib/samba-for-ps2/bind-dns"
    "--with-lockdir=/var/lock/samba-for-ps2"
    "--with-piddir=/var/run/samba-for-ps2"
    "--with-statedir=/var/lib/samba-for-ps2"
    "--with-cachedir=/var/cache/samba-for-ps2"
    "--with-logfilebase=/var/log/samba-for-ps2"
    "--with-sockets-dir=/var/run/samba-for-ps2"
    "--with-privileged-socket-dir=/var/lib/samba-for-ps2"
    "--disable-rpath"
    "--without-gettext"
    "--without-winbind"
    "--without-ads"
    "--without-ad-dc"
    "--without-winbind"
    "--without-ldap"
    "--disable-cups"
    "--disable-iprint"
    "--without-pam"
    "--without-quotas"
    "--without-sendfile-support"
    "--disable-avahi"
    "--without-acl-support"
    "--without-automount"
    "--without-libarchive"
    "--disable-glusterfs"
    "--disable-cephfs"
    "--without-acl-support"
    "--without-libarchive"
    "--disable-python"
    "--without-utmp"
    "--without-iconv"
    "--without-dmapi"
    "--without-fam"
    "--without-lttng"
    "--without-json"
  ];

  # python-config from build Python gives incorrect values when cross-compiling.
  # If python-config is not found, the build falls back to using the sysconfig
  # module, which works correctly in all cases.
  PYTHON_CONFIG = "/invalid";

  pythonPath = [ python3Packages.dnspython tdb ];

  preBuild = ''
    export MAKEFLAGS="-j $NIX_BUILD_CORES"
  '';

  # Some libraries don't have /lib/samba in RPATH but need it.
  # Use find -type f -executable -exec echo {} \; -exec sh -c 'ldd {} | grep "not found"' \;
  # Looks like a bug in installer scripts.
  postFixup = ''
    export SAMBA_LIBS="$(find $out -type f -regex '.*\.so\(\..*\)?' -exec dirname {} \; | sort | uniq)"
    read -r -d "" SCRIPT << EOF || true
    [ -z "\$SAMBA_LIBS" ] && exit 1;
    BIN='{}';
    OLD_LIBS="\$(patchelf --print-rpath "\$BIN" 2>/dev/null | tr ':' '\n')";
    ALL_LIBS="\$(echo -e "\$SAMBA_LIBS\n\$OLD_LIBS" | sort | uniq | tr '\n' ':')";
    patchelf --set-rpath "\$ALL_LIBS" "\$BIN" 2>/dev/null || exit $?;
    patchelf --shrink-rpath "\$BIN";
    EOF
    find $out -type f -regex '.*\.so\(\..*\)?' -exec $SHELL -c "$SCRIPT" \;

    # Samba does its own shebang patching, but uses build Python
    find "$out/bin" -type f -executable -exec \
      sed -i '1 s^#!${python3Packages.python.pythonForBuild}/bin/python.*^#!${python3Packages.python.interpreter}^' {} \;

    # Fix PYTHONPATH for some tools
    wrapPythonPrograms
  '';

  passthru = {
    tests.samba = nixosTests.samba;
  };

  meta = with lib; {
    homepage = "https://www.samba.org";
    description = "The standard Windows interoperability suite of programs for Linux and Unix";
    license = licenses.gpl3;
    platforms = platforms.unix;
    maintainers = with maintainers; [ aneeshusa ];
  };
}
