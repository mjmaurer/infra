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
    ../../modules/graphics/intel.nix
    ../../modules/supermicro/supermicro.nix

    ./hardware-configuration.nix
    ./disko.nix
    ./media.nix
  ];

  config = {
    # services.auto-cpufreq.enable = true;

    modules.sops.enableMinimalSecrets = true;

    modules.duplicacy.repos = {
      "nas-backup" = {
        repoId = "nas";
        localRepoPath = "/mnt/nas-safety-tmp-sdd";
        autoInitRestore = true;
      };
    };

    # ------------------------- Initial Install Config -------------------------

    sops.secrets.oneTimeTailscaleAuthKey = {
      sopsFile = ./secrets.yaml;
    };

    # Intel NIC (retrieve via lspci -k)
    boot.initrd.availableKernelModules = [ "e1000e" ];

    modules.networking = {
      wiredInterfaces = [
        "eno1"
        "enp0s20f0u4u2c2"
      ];
    };

    networking = {
      # Unique host ID for ZFS.
      # Can generate with:
      #   echo $(hostname) | sha256sum | awk '{print substr($1,1,8)}'
      hostId = "0d2ebf8c";
    };
  };
}
