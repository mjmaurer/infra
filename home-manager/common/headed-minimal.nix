{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/headless.nix

    ../modules/wayland.nix
    ../modules/firefox.nix
    ../modules/alacritty/alacritty.nix
  ];

  modules = { alacritty.enable = lib.mkDefault true; };
}
