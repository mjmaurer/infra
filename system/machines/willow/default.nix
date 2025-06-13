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
    ./media.nix

    ./disko.nix
    ./disko-patches/media1.nix
    ./disko-patches/nas1.nix
  ];

  config = {
    # services.auto-cpufreq.enable = true;

    modules.sops.enableMinimalSecrets = true;

    modules.duplicacy = {
      enableServices = true;
      repos = {
        "nas-backup" = {
          repoId = "nas";
          localRepoPath = "/mnt/nas-safety-tmp-sdd";
          # autoInitRestore = true;
        };
        "nas" = {
          repoId = "nas";
          localRepoPath = "/nas";
          # autoInitRestore = true;
        };
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
