{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  autoreconfHook,
  libsForQt5,
}:
stdenv.mkDerivation rec {
  pname = "opl-pc-tools";
  version = "3.0";

  src = fetchFromGitHub {
    owner = "brainstream";
    repo = "OPL-PC-Tools";
    rev = "edf4e72ffdf2d67895b682638215bd5db0b31e40";
    sha256 = lib.fakeSha256;
  };

  nativeBuildInputs = [libsForQt5.wrapQtAppsHook cmake autoreconfHook];
  buildInputs = [libsForQt5.qt5.qtbase];

  cmakeFlags = ["-DMARCH=x86_64"];
}
