{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  kdePackages,
}:
stdenv.mkDerivation rec {
  pname = "cutelee";
  version = "4f17d95";

  src = fetchFromGitHub {
    owner = "cutelyst";
    repo = "cutelee";
    rev = "4f17d959cc9397f25d098d899687d3f8519a2f02";
    sha256 = "16lwhhqcv8rz7hdqi5rnrqwnpqpbcwmm8ppaqaj4mq9aqawccjfl";
  };

  buildInputs = [kdePackages.qtbase kdePackages.qtdeclarative kdePackages.qttools];
  nativeBuildInputs = [cmake pkg-config];

  preInstall = ''
    find . -name "*.pc" -exec sed -i '/^libdir=/ s|//|/|g' {} \;
  '';
  dontWrapQtApps = true;
}
