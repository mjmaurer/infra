{ config, pkgs, ... }:

{
  imports = [ ./base.nix ];
  programs.bash = { shellAliases = { }; };
  home.homeDirectory = "/home/${config.home.username}";
}
