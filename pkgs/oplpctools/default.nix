{
  stdenv,
  lib,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  cmake,
  qt6,
}:
stdenv.mkDerivation rec {
  pname = "oplpctools";
  version = "3.1";

  src = fetchFromGitHub {
    owner = "brainstream";
    repo = "OPL-PC-Tools";
    rev = version;
    sha256 = "sha256-Qn7V/N2K+0BQUXj9lirZsWzTvXcxqbBOTOLYS4rmuUk=";
  };

  nativeBuildInputs = [
    qt6.wrapQtAppsHook
    cmake
    copyDesktopItems
    qt6.qttools
  ];
  buildInputs = [
    qt6.qtbase
    qt6.qttranslations
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
    mkdir -p $out/share/applications
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "OPL PC Tools";
      categories = ["Game" "Utility"];
    })
  ];
}
