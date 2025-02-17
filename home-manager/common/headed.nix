{ config, pkgs, lib, ... }:

{
  imports = [
    ./headed-minimal.nix

    ../modules/vscode

    ../modules/ente-auth/ente-auth.nix
    ../modules/continuedev/continuedev.nix
    ../modules/obsidian/obsidian.nix
  ];

  # When adding here, consider if these should be disabled for some OS.
  modules = {
    continuedev = {
      enable = lib.mkDefault true;
      justConfig = true;
    };
    obsidian = {
      enable = true;
      justConfig = true;
    };
  };
}
