
# See: https://github.com/nix-community/disko/blob/master/example/zfs-with-vdevs.nix
# To setup vdevs
let
  # [0, 0] 
  nasDisk1 = "/dev/disk/by-id/wwn-0x50014ee2c13633f8";
  # [0, 2] 
  nasDisk2 = "/dev/disk/by-id/wwn-0x50014ee26a4a1377";
  nasPoolName = "znas";

  mkNasDisk = devicePath: nameSuffix: {
    device = devicePath;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        luks = {
          name = "${nameSuffix}-luks";
          label = "${nameSuffix}-luks";
          size = "100%";
          content = {
            type = "luks";
            name = "${nameSuffix}-luks";
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
in
{
  disko.devices = {
    disk = {
      nas1 = mkNasDisk nasDisk1 "nas1";
      nas2 = mkNasDisk nasDisk2 "nas2";
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
          autoexpand = "on";
        };
        datasets = {
          "nas" = {
            type = "zfs_fs";
            mountpoint = "/${nasPoolName}";
            options = {
              xattr = "sa";
              atime = "off";
            };
          };
        };
      };
    };
  };
}
