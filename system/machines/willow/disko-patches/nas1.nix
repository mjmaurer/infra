let
  # [0, 0]
  nasDisk1 = "/dev/disk/by-id/wwn-0x50014ee2c13633f8";
  nasDisk1Label = "nas1-luks";
  # [0, 2]
  nasDisk2 = "/dev/disk/by-id/wwn-0x50014ee26a4a1377";
  nasDisk2Label = "nas2-luks";
  nasPool = "znas";
  nasMnt = "nas";

  mkNasDisk = devicePath: name: {
    device = devicePath;
    type = "disk";
    content = {
      type = "gpt";
      partitions.luks = {
        name = name;
        label = name;
        size = "100%";
        content = {
          type = "luks";
          name = name;
          extraFormatArgs = [
            "--pbkdf argon2i"
            "--use-random"
          ];
          extraOpenArgs = [ "--allow-discards" ];
          initrdUnlock = true;
          passwordFile = "/tmp/disk.key";
          content = {
            type = "zfs";
            pool = nasPool;
          };
        };
      };
    };
  };
in
{
  disko.devices = {
    disk = {
      "${nasDisk1Label}" = mkNasDisk nasDisk1 nasDisk1Label;
      "${nasDisk2Label}" = mkNasDisk nasDisk2 nasDisk2Label;
      # In the future just add:
      # nas3 = mkNasDisk "/dev/disk/by-id/…" "nas3";
      # nas4 = mkNasDisk "/dev/disk/by-id/…" "nas4";
    };

    zpool.${nasPool} = {
      type = "zpool";
      mode = {
        topology = {
          type = "topology";
          vdev = [
            {
              mode = "mirror";
              members = [
                # This is the format zpool.nix wants
                "/dev/mapper/${nasDisk1Label}"
                "/dev/mapper/${nasDisk2Label}"
              ];
            }
            # later:
            # { mode = "mirror";  members = [ "nas3-luks" "nas4-luks" ]; }
          ];
        };
      };
      # See disko-common.nix for explanation of root dataset
      rootFsOptions = {
        canmount = "off";
        mountpoint = "none";
        compression = "lz4";
        "com.sun:auto-snapshot" = "false";
      };
      options = {
        ashift = "12";
        autoexpand = "on";
      };

      datasets.nas = {
        type = "zfs_fs";
        mountpoint = "/${nasMnt}";
        mountOptions = [
          "nofail" # Don't fail boot if the pool is not available
          # "zfsutil"
          # "noauto"
        ];
        options = {
          # Don't use zfs mount, use systemd mount instead
          # (configured above via mountOptions / mountpoint)
          mountpoint = "legacy";
          xattr = "sa";
          atime = "off";
        };
      };
    };
  };
}
