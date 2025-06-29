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
    ../../modules/samba/smb-server.nix

    ./hardware-configuration.nix
    ./media.nix

    ./disko.nix
    ./disko-patches/media1.nix
    # ./disko-patches/nas1.nix
  ];

  config = {
    # services.auto-cpufreq.enable = true;

    # systemd.services.zfs-mount.enable = false;

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

    modules.smbServer = {
      recyclePath = "/nas/recycle";
      shares = {
        "full" = {
          path = "/nas";
          comment = "Full Share";
          browseable = true;
          readOnly = true;
          guestOk = false;
          validUsers = [ "mjmaurer" ];
          forceGroup = "nas";
        };
        "content" = {
          path = "/nas/content";
          comment = "Content Share";
          browseable = true;
          readOnly = false;
          guestOk = false;
          validUsers = [ "@nas" ];
          forceGroup = "nas";
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
