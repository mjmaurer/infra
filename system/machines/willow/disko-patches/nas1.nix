let
  nasDisk1 = "/dev/disk/by-id/wwn-0x50014ee2c13633f8";
  nasPoolName = "znas";
in
{
  disko.devices = {
    disk = {
      nas1 = {
        device = nasDisk1;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              name = "nas1-luks";
              label = "nas1-luks";
              size = "100%";
              content = {
                type = "luks";
                name = "nas1-luks";
                extraFormatArgs = [
                  "--pbkdf argon2i"
                  "--use-random"
                ];
                initrdUnlock = true;
                extraOpenArgs = [ "--allow-discards" ];
                passwordFile = "/tmp/disk.key";
                content = {
                  type = "zfs";
                  pool = nasPoolName;
                };
              };
            };
          };
        };
      };
    };
    zpool = {
      "${nasPoolName}" = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          canmount = "off";
          mountpoint = "none";
          compression = "lz4";
          "com.sun:auto-snapshot" = "false";
        };
        options = {
          ashift = "12";
        };
        datasets = {
          "nas" = {
            type = "zfs_fs";
            mountpoint = "/${nasPoolName}";
          };
        };
      };
    };
  };
}
