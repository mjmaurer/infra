{ config, pkgs, ... }:

{
  imports = [ ./base.nix ];

  configuration = {
    obsidian = {
      enable = true;
    };
    aerospace.enable = true;
  };

  home.homeDirectory = "/Users/${config.home.username}";

  modules.commonShell = {
    sessionVariables = { MACHINE_NAME = "smac"; };
    shellAliases = {
      "la" = "ls -A -G";
      "ls" = "ls -G";
    };
  };
}
