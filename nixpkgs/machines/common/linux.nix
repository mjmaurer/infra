{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ../../modules/tmux/tmux.nix
  ];
  home.homeDirectory = "/home/${config.home.username}";
}
