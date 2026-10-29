{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "hpwnr";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "Omegaplexx";
    repo = "hpwnr";
    rev = "v${finalAttrs.version}";
    hash = "sha256-bAf2essRr8oz3W7XXvYbQwjewwU2A8Q5gcAGFAHWIzc=";
  };

  cargoHash = "sha256-G6hpMQAUcZRWSMuMOr1V9eOvMmIeo7evykh3kRTT2sY=";

  patches = [
    ./force-stdout.patch
  ];

  meta = {
    description = "CLI for fetching and converting Happ and v2RayTun proxy profiles";
    homepage = "https://github.com/Omegaplexx/hpwnr";
    mainProgram = "hpwnr";
    platforms = lib.platforms.linux;
  };
})
