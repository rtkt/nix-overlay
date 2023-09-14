{
  lib,
  stdenv,
  fetchFromGitHub
}:
stdenv.mkDerivation rec {
  pname = "nginx-dns";
  version = "1";

  src = fetchFromGitHub {
    owner = "TuxInvader";
    repo = "nginx-dns";
    rev = "3ed6d1e892c11fa0cf44759d53540f6e32ad9f47";
    sha256 = "sha256-bfAMA9V8nJ6Wit/0+BOpo0+IEMKShvHqGEXaYtXgXA0=";
  };

  installPhase = ''
    mkdir -p "$out"
    cd "njs.d/dns"
    cp -t "$out" $(ls)    
  '';
}
