{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  libsForQt5,
  libglvnd,
  libxkbcommon,
  libxcb,
}:
stdenv.mkDerivation rec {
  pname = "opl-pc-tools";
  version = "3.0";

  src = fetchFromGitHub {
    owner = "brainstream";
    repo = "OPL-PC-Tools";
    rev = "edf4e72ffdf2d67895b682638215bd5db0b31e40";
    sha256 = "sha256-DCdmlyzta2gmqmXjV5NuQj5BgimifBFKIU7rk1OS4pw=";
  };

  patches = [
    ./0001-Renamed-QT5_DIR-to-Qt5_DIR.patch
  ];

  nativeBuildInputs = [libsForQt5.wrapQtAppsHook cmake];
  buildInputs = with libsForQt5.qt5; [qtbase qttranslations libglvnd libxkbcommon libxcb];

  cmakeFlags = ["-DMARCH=x86_64"];
}
