{ config, lib, ... }:
{
  # Never change this here.
  home.stateVersion = lib.mkDefault "24.11";

  imports = [
    ./_base.nix
    ../modules/programs.nix
  ];
}

