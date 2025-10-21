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
    ../../modules/graphics/skylake.nix

    ./hardware-configuration.nix
    ./disko.nix
  ];

  config = {

    sops.secrets.oneTimeTailscaleAuthKey = {
      sopsFile = ./secrets.yaml;
    };

    # Firmware is essential for i915 driver
    hardware.firmware = [ pkgs.linux-firmware ];

    # Intel NIC (retrieve via lspci -k)
    boot.initrd.availableKernelModules = [ "e1000e" ];

    # TODO: should be exact with these
    modules.networking = {
      wiredInterfaces = [
        "en*"
        "eth*"
      ];
      wirelessInterfaces = [
        "wl*"
      ];
      tailscaleSubnetRouter = {
        enabled = true;
        subnet = "172.48.0.1/24";
      };
    };

    networking = {
      # Unique host ID for ZFS.
      # Can generate with:
      #   echo $(hostname) | sha256sum | awk '{print substr($1,1,8)}'
      hostId = "02eb912a";
    };

    # Misc settings from: https://blog.ktz.me/how-to-enable-intel-quicksync-on-nixos-with-a-supermicro-x13sae-f-and-an-intel-i5-13600k-2/
    # boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    # boot.kernelParams = [
    #   "i915.fastboot=1"
    #   "i915.enable_guc=3"
    # ];
    # boot.supportedFilesystems = [ "zfs" ];
    # boot.zfs.extraPools = [
    #   "nvme-appdata"
    #   "ssd4tb"
    #   "bigrust18"
    # ];
    # services.zfs.autoScrub.enable = true;
  };
}
