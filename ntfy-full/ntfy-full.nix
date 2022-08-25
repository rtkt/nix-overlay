{ lib, buildGoModule, fetchgit, npm, nodejs, git, gnumake, bash }:

buildGoModule rec {
  pname = "ntfy-sh";
  version = "1.27.2";

  src = fetchgit {
    url = "https://github.com/binwiederhier/ntfy.git";
    rev = "69d6cdd786260c3d2d83a31d7256a57eceb82b27";
    sha256 = "sha256-UW114Xw/0vraSsJHLTXZIGv055iVP3Lne4gJOKct4HQ=";
    leaveDotGit = true;
  };

  vendorSha256 = "sha256-PXYSjhMNtDa0uCaLu0AyM1SMhZPr2wC+xMPDjeQIhDU=";

  doCheck = false;

  preBuild = ''
    export PATH=PATH:${bash}/bin:${npm}/bin:${nodejs}/bin:${git}/bin:${gnumake}/bin
    make web
  '';

  meta = with lib; {
    description = "Send push notifications to your phone or desktop via PUT/POST";
    homepage = "https://ntfy.sh";
    license = licenses.asl20;
    maintainers = with maintainers; [ arjan-s ];
  };
}
