{ config, lib, ... }: {
  # Never change this here.
  system.stateVersion = lib.mkDefault "24.11";

  imports = [ ./_base.nix ../modules/programs.nix ];
}

