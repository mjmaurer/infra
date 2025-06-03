{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.impermanence;
in
{
  options.modules.impermanence = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    impermanenceMntPath = lib.mkOption {
      type = lib.types.str;
      default = "/impermanence";
    };
  };

  config = lib.mkIf cfg.enabled {
    # Enable impermanence module
    environment.persistence.${cfg.impermanenceMntPath} = {
      # Hide these mounts from the sidebar of file managers
      # hideMounts = true;

      directories = [
        "/root"
        "/etc/nixos"
        "/etc/duplicacy"
        "/etc/ssh"
        "/etc/udev"
        "/etc/wpa_supplicant.conf"
        "/etc/NetworkManager/system-connections"
        "/var/log"
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
