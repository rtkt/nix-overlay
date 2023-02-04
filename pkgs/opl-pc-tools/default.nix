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
    rev = "v3.0";
    sha256 = "0vbm097jhi5n8pg08ia1yhzc225zv9948blb76f4br739l9l22vq";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [libsForQt5.wrapQtAppsHook cmake autoreconfHook];
  buildInputs = [libsForQt5.qt5.qtbase];

  cmakeFlags = ["-DMARCH=x86_64"];
}
