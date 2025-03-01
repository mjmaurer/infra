{ }:
let
  zfsPoolName = "zroot";
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            efi = {
              type = "EF00";
              name = "efi";
              start = "1M";
              size = "1G";
              # uuid = "XXXXX-XXXX-XXXX-BA4B-00A0C93EC93B";
              # label = "EFI System Partition";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypt-main";
                extraFormatArgs = [
                  "--pbkdf argon2i"
                  "--use-random"
                ];
                # Adds 'luks.devices.{luks.content.name}.device = {device}' to config
                initrdUnlock = true;
                # Better SSD performance
                extraOpenArgs = [ "--allow-discards" ];
                passwordFile = "/tmp/disk.key";
                content = {
                  type = "zfs";
                  # Can add this to multiple zfs partitions (for other machine config)
                  pool = zfsPoolName;
                };
              };
            };
          };
        };
      };
    };
    zpool = {
      ${zfsPoolName} = {
        type = "zpool";
        # mode = "mirror";
        rootFsOptions = {
          canmount = "off";
          mountpoint = "none";
          # Comparison: https://facebook.github.io/zstd/
          compression = "lz4";
          # I probably don't need ACL config, but may be useful for samba
          # It creates issues with backup solutions like duplicacy
          # acltype = "posixacl";
          # xattr = "sa"; # Default
          "com.sun:auto-snapshot" = "false";
        };
        options.ashift = "12";
        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
            # postCreateHook = "zfs snapshot zfspool/root@blank";
            # "com.sun:auto-snapshot" = "true";
          };
          "root/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
          "root/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            # "com.sun:auto-snapshot" = "true";
          };
          "root/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            # postCreateHook = "zfs snapshot zfspool/home@blank";
            # "com.sun:auto-snapshot" = "true";
          };
          "root/tmp" = {
            type = "zfs_fs";
            mountpoint = "/tmp";
          };
          # Can maybe remove these (make temp) after move to impermancne
          "root/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
          };
          "root/var/lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
          };
        };
      };
    };
  };
}
