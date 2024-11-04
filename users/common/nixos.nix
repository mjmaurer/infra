{ config, pkgs, ... }:

{
  imports = [ ./linux.nix ];

  # These are managed by NixOS.
  home.username = null;
  home.homeDirectory = null;

  modules.commonShell = {
    machineName = config.networking.hostName;
  };
}
