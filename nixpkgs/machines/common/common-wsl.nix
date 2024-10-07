{ config, pkgs, ... }:

{
  programs.bash = { shellAliases = { }; };
  home.homeDirectory = "/home/${config.home.username}";
  imports = [
      ../modules/tmux/tmux.nix
  ];
}
