{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  libsForQt5,
  libglvnd,
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

  nativeBuildInputs = [libsForQt5.wrapQtAppsHook cmake];
  buildInputs = with libsForQt5.qt5; [qtbase qttranslations libglvnd];

  cmakeFlags = ["-DMARCH=x86_64"];
}
