# Includes SSH, GPG, and Yubikey
{ lib, isDarwin, derivationName, pkgs, ... }:
let
  isNixOS = !isDarwin;
in
lib.mkMerge [
  (lib.optionalAttrs isNixOS {
    # Give Yubikey access to the udev (device) rules
    services.udev.packages = with pkgs; [
      yubikey-personalization
    ];

    # Smartcard communication daemon
    services.pcscd.enable = true;
  })
  (lib.optionalAttrs isDarwin { })
]
