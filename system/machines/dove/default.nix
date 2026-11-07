{
  config,
  lib,
  pkgs,
  derivationName,
  username,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./proxy.nix
  ];

  config = {

    sops.secrets = {
      oneTimeTailscaleAuthKey = {
        sopsFile = ./secrets.yaml;
      };
      mjmaurerHashedPassword = {
        neededForUsers = true;
        sopsFile = ./secrets.yaml;
      };
    };

    boot.loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    modules.networking = {
      wiredInterfaces = [ "ens3" ];
    };

    # No AI tooling on dove (overrides the mkDefault true in home-manager/common/headless.nix).
    # The separate `ai` system user from system/modules/users.nix is intentionally kept.
    home-manager.users.${username}.modules = {
      ai.enable = false;
      claude.enable = false;
      pi.enable = false;
      aichat.enable = false;
      llm.enable = false;
      codex-cli.enable = false;
    };

    networking = {
      # Unique host ID for ZFS.
      # Can generate with:
      #   echo $(hostname) | sha256sum | awk '{print substr($1,1,8)}'
      hostId = "8e500d81";
    };
  };
}
