{
  stdenv,
  lib,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  cmake,
  qt5,
}:
stdenv.mkDerivation rec {
  pname = "oplpctools";
  version = "3.0";

  src = fetchFromGitHub {
    owner = "brainstream";
    repo = "OPL-PC-Tools";
    rev = "edf4e72ffdf2d67895b682638215bd5db0b31e40";
    sha256 = "sha256-DCdmlyzta2gmqmXjV5NuQj5BgimifBFKIU7rk1OS4pw=";
  };

  patches = [
    ./0001-Rename-QT5_DIR-to-Qt5_DIR.patch
  ];

  nativeBuildInputs = [
    qt5.wrapQtAppsHook
    cmake
    copyDesktopItems
  ];
  buildInputs = [
    qt5.qtbase
    qt5.qttranslations
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp oplpctools $out/bin
    cp ./*.qm $out/bin
    cp ../LICENSE.txt $out
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ../src/OplPcTools/Resources/images/application.png $out/share/icons/hicolor/256x256/apps/oplpctools.png
    runHook postInstall
  '';

  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    desktopName = "OPL PC Tools";
    categories = ["Game" "Utility"];
  };
}
