{ config, pkgs, ... }:

{
  imports = [
    ../modules/aider/aider.nix
  ];

  home.homeDirectory = "/Users/${config.home.username}";

}
