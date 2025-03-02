{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{

  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  config = {

    sops.secrets.oneTimeTailscaleAuthKey = {
      sopsFile = ./secrets.yaml;
    };

    services.xserver.videoDrivers = [ "intel" ];
    # Consider: https://github.com/NixOS/nixos-hardware/tree/master/common/gpu/intel

    networking = {
      # Unique host ID for ZFS.
      # Can generate with:
      #   echo $(hostname) | sha256sum | awk '{print substr($1,1,8)}'
      hostId = "02eb912a";
    };

    environment.systemPackages = [
      # To enable `intel_gpu_top`
      pkgs.intel-gpu-tools
    ];

    #  (See `hardware.graphics` below) Force use of iHD driver, but Nix says Skylake has trouble.
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    }; # or 'i965'

    hardware = {
      # Should be set in hardware-configuration.nix:
      # cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware; Should be set in hardware-configuration.nix

      # https://download.lenovo.com/parts/ThinkCentre/m700_tiny_overview.pdf
      # (Skylake)
      # https://www.intel.com/content/www/us/en/products/sku/88183/intel-core-i56500t-processor-6m-cache-up-to-3-10-ghz/specifications.html
      # https://nixos.wiki/wiki/Intel_Graphics
      # https://nixos.wiki/wiki/Accelerated_Video_Playback
      # Good intel media stack wiki: https://github.com/intel/media-driver/wiki
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          # Older driver for fallback (previously vaapiIntel):
          intel-vaapi-driver # LIBVA_DRIVER_NAME=i965
          # Newer driver:
          intel-media-driver # LIBVA_DRIVER_NAME=iHD
          # Even newer (previously onevpl-intel-gpu)
          # See here for when to to use this vs media-driver:
          # https://github.com/intel/libvpl?tab=readme-ov-file#dispatcher-behavior-when-targeting-intel-gpus
          vpl-gpu-rt

          # OpenCL filter support (hardware tonemapping and subtitle burn-in)
          intel-compute-runtime

          # Don't think I need these:
          # See https://wiki.archlinux.org/title/Hardware_video_acceleration#Verification
          # vaapiVdpau # think VDPAU is just for nvidia
          # libvdpau-va-gl # compat layer that translates VDPAU calls to VA-API (va-api is natively supported by quicksync)
        ];
        nixpkgs.config.packageOverrides = pkgs: {
          # Hybrid driver might provide VP9 for skylake, but this was also archived a long time ago.
          # Probably don't need VP9 (it's video codec), and could comment out if trouble
          intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
        };
      };
    };

    # This assumes boot parition is unencrypted, and root parititon is encrypted with luks.
    # https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition
    # Could use secureboot / tpm / ima integrity
    boot = {
      # There are other examples for different machines
      # in the original repo for EFI, Windows, Nvidia, etc.
      loader = {
        efi = {
          canTouchEfiVariables = true;
          # efiSysMountPoint = "/boot"; This was set in original repo
        };
        grub = {
          enable = true;
          efiSupport = true;
          # disko will add devices that have a EF02 partition here:
          # devices = [ ];
        };
      };
      # This was in the dropbear nix thread:
      # kernelParams = ["ip=:::::eth0:dhcp"];
      kernelParams = [ "ip=dhcp" ];
      initrd = {
        # Run: lspci -k | grep -EA3 'VGA|3D|Display'
        # Early loading so the passphrase prompt appears on external displays
        # kernelModules = [ "i915" ];
        # Intel NIC
        # availableKernelModules = [ "e1000e" ]; Probably set in hardware-configuration.nix
        # Configure Dropbear SSH server for remote boot with encrypted drives
        # https://discourse.nixos.org/t/disk-encryption-on-nixos-servers-how-when-to-unlock/5030/13
        # https://wiki.archlinux.org/title/Dm-crypt/Specialties#Remote_unlocking_of_the_root_(or_other)_partition
        network = {
          enable = true;
          # wait-online = {
          #   enable = true;
          #   timeout = 60;
          # };
          ssh = {
            enable = true;
            port = 2222;
            # Prompt for the LUKS encryption password during early boot
            shell = "/bin/cryptsetup-askpass";
            hostKeys = [ "/nix/secret/initrd/ssh_host_ed25519_key" ];
            authorizedKeys = config.users.users.${username}.openssh.authorizedKeys.keys;
          };
        };
      };
    };

    # This would be needed for impermance:
    # fileSystems."/etc/ssh".neededForBoot = true;
  };
}
