{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  kdePackages,
  cutelee,
  cutelyst,
  libvirt,
}:
stdenv.mkDerivation rec {
  pname = "virtlyst";
  version = "77aeffe";

  src = fetchFromGitHub {
    owner = "cutelyst";
    repo = "Virtlyst";
    rev = "77aeffe274f8d186f08462310bd71d37a4e68428";
    sha256 = "0hxdva7d96crvk04h13yv8r8nphy0l8pwdr2a8pdf6aiiydzk052";
  };

  buildInputs = [kdePackages.qtbase kdePackages.qtscxml cutelyst cutelee libvirt];
  nativeBuildInputs = [cmake pkg-config];
  installPhase = ''
    echo $(pwd)
    mkdir -p $out/lib
    cp src/libVirtlyst.so $out/lib
    cp -R ../root $out
  '';
  dontWrapQtApps = true;
}
