final: prev: let
  inherit (prev) lib;
  overlay = subset: extra: let
    super = prev;
    self = final."${subset}";
    callPackage = super.lib.callPackageWith (final // self);
  in {
    "${subset}" = {
      pkgs = final;
      samba-for-ps2 = callPackage ./samba-for-ps2;
      ntfy-full = callPackage ./ntfy-full;
      ntfy-webapp = callPackage ./ntfy-webapp;
      tcpflow = callPackage ./tcpflow;
    };
  };
in
  overlay {}
