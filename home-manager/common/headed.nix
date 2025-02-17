{ config, pkgs, lib, ... }:

{
  imports = [
    ./headed-minimal.nix
    ../modules/ente-auth/ente-auth.nix
    ../modules/continuedev/continuedev.nix
    ../modules/obsidian/obsidian.nix
  ];

  modules = {
    continuedev = {
      enable = lib.mkDefault true;
      justConfig = true;
    };
  };
}
