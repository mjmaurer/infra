{ config, pkgs, ... }:

{
  imports = [
    ./base.nix
    ../../modules/aider/aider.nix
    ../../modules/aerospace/aerospace.nix
    ../../modules/tmux/tmux.nix
    ../../modules/obsidian/obsidian.nix
  ];

  configuration = {
    obsidian = {
      enable = true;
    };
  };

  home.homeDirectory = "/Users/${config.home.username}";
}
