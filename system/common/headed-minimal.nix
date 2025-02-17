{ config, kanataPkg, pkgs, lib, ... }: {

  # When adding to Darwin when adding here
  imports = [
    ../modules/wayland.nix
    ../modules/xserver.nix
    ../modules/kanata/kanata.nix
    ../modules/crypt.nix # Yubikey stuff
  ];
}
