{
  config,
  kanataPkg,
  pkgs,
  lib,
  ...
}:
{

  # ---------------------------------- NOTE ----------------------------------
  # Consider adding to cloud.nix / darwin.nix when adding here
  imports = [
    ../modules/nix.nix
    ../modules/basic.nix
    ../modules/users.nix
    ../modules/networking.nix
    ../modules/smb-client.nix
    ../modules/audio.nix
    ../modules/boot.nix
    ../modules/ssh.nix

    ../modules/sops
    ../modules/duplicacy/duplicacy.nix
    ../modules/mergerfs.nix
  ];

  config = {
    # Just installs the packages, not the services
    modules.duplicacy.enable = true;
  };
}
