# Includes SSH, GPG, and Yubikey
{
  lib,
  isDarwin,
  derivationName,
  pkgs,
  ...
}:
let
  isNixOS = !isDarwin;
in
lib.mkMerge [
  (
    if isDarwin then
      {
      }
    else
      # NixOS
      {

        # Give Yubikey access to the udev (device) rules
        services.udev.packages = with pkgs; [ yubikey-personalization ];

        # Smartcard communication daemon. Includes PKCS#11 support.
        services.pcscd.enable = true;
        # Required by pcsc-lite:
        security.polkit.enable = true;
      }
  )
]
