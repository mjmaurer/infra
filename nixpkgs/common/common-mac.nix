{ config, pkgs, ... }:

{
  imports = [
    ../modules/aider/aider.nix
    ../modules/aerospace/aerospace.nix
    ../modules/tmux/tmux.nix
  ];

  home.homeDirectory = "/Users/${config.home.username}";

}
