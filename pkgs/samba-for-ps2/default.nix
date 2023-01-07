{
  lib,
  stdenv,
  buildPackages,
  fetchurl,
  wafHook,
  pkg-config,
  bison,
  flex,
  perl,
  libxslt,
  docbook_xsl,
  docbook_xml_dtd_45,
  popt,
  zlib,
  liburing,
  gnutls,
  systemd,
  libtasn1,
  rpcsvc-proto,
  bash,
  python3Packages,
  nixosTests,
}:
with lib;
  stdenv.mkDerivation rec {
    pname = "samba-for-ps2";
    version = "4.17.4";

    src = fetchurl {
      url = "mirror://samba/pub/samba/stable/samba-${version}.tar.gz";
      sha256 = "sha256-wFEgedtMrHB8zqTBiuu9ay6zrPbpBzXn9kWjJr4fRTc=";
    };

    outputs = ["out" "dev" "man"];

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
      perl.pkgs.JSON
      libxslt
      buildPackages.stdenv.cc
      docbook_xsl
      docbook_xml_dtd_45
      rpcsvc-proto
    ];

    buildInputs = [
      bash
      python3Packages.wrapPython
      python3Packages.python
      popt
      zlib
      gnutls
      libtasn1
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
      export PYTHONHASHSEED=1
    '';

    wafConfigureFlags = [
      "--with-static-modules=NONE"
      "--with-shared-modules=!DEFAULT"
      "--bundled-libraries=ALL"
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
      "--disable-python"
      "--without-utmp"
      "--without-iconv"
      "--without-dmapi"
      "--without-fam"
      "--without-lttng"
      "--without-json"
      "--with-smb1-server"
    ];

    # python-config from build Python gives incorrect values when cross-compiling.
    # If python-config is not found, the build falls back to using the sysconfig
    # module, which works correctly in all cases.
    PYTHON_CONFIG = "/invalid";

    pythonPath = [];

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

      # Fix PYTHONPATH for some tools
      wrapPythonPrograms

      # Samba does its own shebang patching, but uses build Python
      find $out/bin -type f -executable | while read file; do
        isScript "$file" || continue
        sed -i 's^${lib.getBin buildPackages.python3Packages.python}/bin^${lib.getBin python3Packages.python}/bin^' "$file"
      done
    '';

    disallowedReferences =
      lib.optionals (buildPackages.python3Packages.python != python3Packages.python)
      [buildPackages.python3Packages.python];

    passthru = {
      tests.samba = nixosTests.samba;
    };

    meta = with lib; {
      homepage = "https://www.samba.org";
      description = "The standard Windows interoperability suite of programs for Linux and Unix";
      license = licenses.gpl3;
      platforms = platforms.unix;
      # maintainers = with maintainers; [aneeshusa];
    };
  }
