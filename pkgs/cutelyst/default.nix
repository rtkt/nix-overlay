{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  kdePackages,
  enableCutelee ? true,
  cutelee,
}:
stdenv.mkDerivation rec {
  pname = "cutelyst";
  version = "4.0.0";
  src = fetchFromGitHub {
    owner = "cutelyst";
    repo = "cutelyst";
    rev = "v4.0.0";
    sha256 = "15nfljq0rwdakg5ii6dndgvwknn5ybz6kwasznyzjps40j0f1hd3";
  };
  buildInputs = [kdePackages.qtbase kdePackages.qttools] ++ lib.optionals enableCutelee [cutelee];
  nativeBuildInputs = [cmake pkg-config];
  cmakeFlags = [] ++ lib.optionals enableCutelee ["-DPLUGIN_VIEW_CUTELEE=ON"];
  preInstall = ''
    find . -name "*.pc" -exec sed -i '/^libdir=/ s|//|/|g' {} \;
  '';
  dontWrapQtApps = true;
}
