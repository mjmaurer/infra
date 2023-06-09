{ config, pkgs, ... }:

{
  home.homeDirectory = "/Users/${config.home.username}";
}
