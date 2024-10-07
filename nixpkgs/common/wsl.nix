{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ../modules/tmux/tmux.nix
  ];
  programs.bash = { shellAliases = { }; };
  home.homeDirectory = "/home/${config.home.username}";
}
