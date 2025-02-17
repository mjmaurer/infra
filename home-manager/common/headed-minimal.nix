{ config, pkgs, lib, ... }:

{
  imports = [
    ./headless.nix

    ../modules/wayland/wayland.nix
    ../modules/firefox/firefox.nix
    ../modules/alacritty/alacritty.nix
  ];

  # When adding here, consider if these should be disabled for some OS.
  modules = {
    alacritty.enable = lib.mkDefault true;
    wayland.enable = lib.mkDefault true;
    firefox.enable = lib.mkDefault true;
  };
}
