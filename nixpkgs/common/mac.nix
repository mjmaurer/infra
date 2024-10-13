{ config, pkgs, ... }:

{
  imports = [ ./base.nix ];

  home.homeDirectory = "/Users/${config.home.username}";

  modules = {
    obsidian = {
      enable = true;
      justConfig = true;
    };
    aerospace = {
      enable = true;
      justConfig = true;
    };

    commonShell = {
      sessionVariables = { MACHINE_NAME = "smac"; };
      shellAliases = {
        "la" = "ls -A -G";
        "ls" = "ls -G";
      };
    };
  };
}
