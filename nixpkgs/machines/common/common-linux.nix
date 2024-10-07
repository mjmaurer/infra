{ config, pkgs, ... }:

{
  imports = [
    ../modules/tmux/tmux.nix
  ];
  home.homeDirectory = "/home/${config.home.username}";
}
