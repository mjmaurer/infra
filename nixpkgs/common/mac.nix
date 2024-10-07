{ config, pkgs, ... }:

{
  imports = [ ./base.nix ];

  configuration = {
    obsidian = {
      enable = true;
    };
  };

  home.homeDirectory = "/Users/${config.home.username}";
}
