{ config, pkgs, lib, ... }:
{
  system.stateVersion = "24.05";

  imports = [
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "core";
    # Unique host ID for ZFS.
    # Can generate with:
    #   echo $(hostname) | sha256sum | awk '{print substr($1,1,8)}'
    hostId = "d1e6e9f2";
  };

  boot = {
    # There are other examples for different machines
    # in the original repo for EFI, Windows, Nvidia, etc.
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/nvme0n1";
    };
    supportedFilesystems = [ "zfs" ];
    # This was in the dropbear nix thread:
    # kernelParams = ["ip=:::::eth0:dhcp"];
    initrd = {
      # Run: lspci -k | grep -EA3 'VGA|3D|Display'
      kernelModules = [ "i915" ];
      luks.devices.crypt-root = {
        device = "/dev/nvme0n1p2";
      };
      # Intel NIC
      availableKernelModules = [ "e1000e" ];
      # Configure Dropbear SSH server for remote boot with encrypted drives
      # https://nixos.wiki/wiki/Remote_disk_unlocking
      # https://discourse.nixos.org/t/disk-encryption-on-nixos-servers-how-when-to-unlock/5030/13
      network = {
        enable = true;
        # wait-online = {
        #   enable = true;
        #   timeout = 60;
        # };
        ssh = {
          enable = true;
          port = 2222;
          hostECDSAKey = /var/src/secrets/dropbear/ecdsa-hostkey;
          # this includes the ssh keys of all users in the wheel group
          authorizedKeys = with lib;
            concatLists (mapAttrsToList
              (name: user:
                if elem "wheel" user.extraGroups
                then user.openssh.authorizedKeys.keys
                else [ ]
              )
              config.users.users);
        };
        # Prompt for the LUKS encryption password during early boot
        # when accessing encrypted drives via SSH
        # NOTE: Nix guide above recommends this in different place
        postCommands = ''
          echo 'cryptsetup-askpass' >> /root/.profile
          # Don't need 'zfs load-key' since not using ZFS encryption (using LUKS full disk encryption)
        '';
      };
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true; # lib.mkDefault config.hardware.enableRedistributableFirmware;
    # https://download.lenovo.com/parts/ThinkCentre/m700_tiny_overview.pdf
    # (Skylake)
    # https://www.intel.com/content/www/us/en/products/sku/88183/intel-core-i56500t-processor-6m-cache-up-to-3-10-ghz/specifications.html
    # https://nixos.wiki/wiki/Intel_Graphics
    # https://nixos.wiki/wiki/Accelerated_Video_Playback
    graphics = {
      enable = true;
      # Could force use of iHD driver, but Nix says Skylake has trouble.
      # environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; };
      # Hybrid driver might provide VP9 for skylake, but archived a long time ago:
      # nixpkgs.config.packageOverrides = pkgs: {
      #     intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
      #   };
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        # Older driver:
        intel-vaapi-driver # LIBVA_DRIVER_NAME=i965
        # Newer driver:
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
      ];
    };
  };

  time = {
    hardwareClockInLocalTime = true;
    timeZone = "America/New_York";
  };

}
