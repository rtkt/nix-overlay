self: super:
{
	tor-browser-bundle-bin = super.tor-browser-bundle-bin.overrideAttrs (finalAttrs: previousAttrs: {
		src = super.fetchurl {
			url = "https://tor.calyxinstitute.org/dist/torbrowser/11.5/tor-browser-linux64-11.5_en-US.tar.xz";
			sha256 = "sha256-Itag51LOYmxDrpDxafHXv0L+zMB6bs3dEdIIddd82cI=";
		};
	});
}