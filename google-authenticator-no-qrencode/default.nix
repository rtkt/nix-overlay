self: super:
{
  google-authenticator = (super.google-authenticator.overrideAttrs (finalAttrs: previousAttrs: {
    preConfigure = null;
  })).override {
    qrencode = null;
  };
}
