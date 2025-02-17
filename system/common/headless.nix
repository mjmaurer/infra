{ config, kanataPkg, pkgs, lib, ... }: {

  # ---------------------------------- NOTE ----------------------------------
  # Consider adding to Darwin when adding here
  imports = [
    ../modules/nix.nix
    ../modules/basic.nix
    ../modules/users.nix
    ../modules/networking.nix
    ../modules/smb-client.nix
    ../modules/audio.nix
    ../modules/boot.nix
    ../modules/ssh.nix
    # TODO ../modules/tailscale.nix

    ../modules/sops
  ];
}
