{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./headed-minimal.nix

    ../modules/vscode

    ../modules/ente-auth/ente-auth.nix
    ../modules/continuedev/continuedev.nix
    ../modules/repomix/repomix.nix
    ../modules/node/node.nix
  ];

  # When adding here, consider if these should be disabled for some OS.
  modules = {
    repomix.enable = lib.mkDefault true;
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
