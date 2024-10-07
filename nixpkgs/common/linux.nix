{ config, pkgs, ... }:

{
  imports = [ ./base.nix ];
  home.homeDirectory = "/home/${config.home.username}";
}
