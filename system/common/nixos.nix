{ config, lib, ... }: {
  # Never change this here.
  system.stateVersion = lib.mkDefault "24.11";

  imports = [
    ./_base.nix

    ../modules/sway.nix
    ../modules/crypt.nix
    ../modules/fonts.nix
    ../modules/audio.nix
    # Move to users?:
    ../modules/sudo.nix
    # Look for others in alice's flake

    ../modules/boot.nix
  ];
}

