{
  config,
  lib,
  pkgs,
  persistMntPath,
  zfsRootPool,
  ...
}:
{
  # Configure the ZFS rollback on boot
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r ${zfsRootPool}/root@blank
  '';

  fileSystems."/etc/ssh".neededForBoot = true;

  # Enable impermanence module
  services.impermanence = {
    enable = true;
    persistentStoragePath = persistMntPath;
    # Hide these mounts from the sidebar of file managers
    # hideMounts = true;

    directories = [
      "/root" # Root user dir
      "/etc/nixos"
      "/etc/duplicacy"
      "/etc/ssh"
      "/etc/udev"
      "/var/log"
      "/var/lib"
      "/etc/NetworkManager/system-connections"
      "/etc/wpa_supplicant.conf"
      # "/var/lib/NetworkManager"
      # "/var/lib/systemd"
      # "/var/lib/nixos" # Crucial for machine-id, UIDs/GIDs
      # "/var/lib/bluetooth"
      # {
      #   directory = "/var/lib/docker"; # Example for Docker
      #   mode = "0755"; # Set appropriate permissions
      #   user = "root";
      #   group = "docker";
      # }
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

}
