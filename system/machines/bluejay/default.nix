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
  ];

  config = {

    nix.settings = {
      download-buffer-size = 104857600; # 100MB
    };

    # sops.secrets = {
    #   oneTimeTailscaleAuthKey = {
    #     sopsFile = ./secrets.yaml;
    #   };
    #   mjmaurerHashedPassword = {
    #     neededForUsers = true;
    #     sopsFile = ./secrets.yaml;
    #   };
    # };

    boot.loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    modules.networking = {
      minimalInstall = true;
      wiredInterfaces = [ "ens3" ];
    };

    networking = {
      # Unique host ID for ZFS.
      # Can generate with:
      #   echo $(hostname) | sha256sum | awk '{print substr($1,1,8)}'
      hostId = "29864028";
    };
  };
}
