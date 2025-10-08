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
    ../../modules/graphics/nvidia.nix
    ../../modules/virtualisation.nix

    ./hardware-configuration.nix

    ./disko.nix
  ];

  config = {
    modules = {
      virt = {
        withPodman = false;
        withDocker = true;
        enableNvidia = true;
      };
      nvidia = {
        enableCUDA = true;
      };
    };

    # Extra home modules to load.
    home-manager.users.${username} = {
      imports = [ ];
    };

    # ------------------------- Initial Install Config -------------------------

    sops.secrets.oneTimeTailscaleAuthKey = {
      sopsFile = ./secrets.yaml;
    };

    # Intel NIC (retrieve via lspci -k)
    # First is 2.5G port, second is 1G
    boot.initrd.availableKernelModules = [
      "r8169"
      "igb"
    ];

    modules.networking = {
      wiredInterfaces = [
        "enp4s0"
        "enp5s0"
      ];
    };

    networking = {
      # Unique host ID for ZFS.
      # Can generate with:
      #   echo $(hostname) | sha256sum | awk '{print substr($1,1,8)}'
      hostId = "d1e0f20b";
    };
  };
}
