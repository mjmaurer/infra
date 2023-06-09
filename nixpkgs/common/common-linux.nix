{ config, pkgs, ... }:

{
  home.homeDirectory = "/home/${config.home.username}";
}
