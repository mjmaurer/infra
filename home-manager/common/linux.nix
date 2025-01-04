# Shared by nixos and other linux systems
{ config, pkgs, lib, ... }:
{
  # This might be set by the home-manager module for NixOS
  # This is kept for HM-only systems
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";
}
