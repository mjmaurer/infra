{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.modules.impermanence = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf config.modules.impermanence.enabled {
    # Configure the ZFS rollback on boot
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r ${config.modules.disko-common.zfsRootPool}/root@blank
    '';

    # Enable impermanence module
    environment.persistence.${config.modules.disko-common.impermanenceMntPath} = {
      # Hide these mounts from the sidebar of file managers
      # hideMounts = true;

      directories = [
        "/root"
        "/etc/nixos"
        "/etc/duplicacy"
        "/etc/ssh"
        "/etc/udev"
        "/etc/wpa_supplicant.conf"
        "/var/log"
        "/etc/NetworkManager/system-connections"
        "/var/lib"
      ];
      files = [
        "/etc/machine-id"
      ];
    };

    # If you're managing home persistence with home-manager:
    # home-manager.users.yourusername = { config, lib, pkgs, ... }: {
    #   targets.genericLinux.enable = true;
    #   home.stateVersion = "23.11"; # Or your current Nixpkgs version
    #   home.persistence = {
    #     "${persistPath}/home/yourusername" = {
    #       directories = [
    #         "Documents"
    #         "Downloads"
    #         "Pictures"
    #         "Videos"
    #         ".config"
    #         ".local/share"
    #         ".ssh"
    #         ".gnupg"
    #         # Add more user-specific directories to persist
    #       ];
    #       files = [
    #         # Add user-specific files to persist
    #         ".bash_history"
    #       ];
    #     };
    #   };
    # };

  };
}
