{ zfsRootPool, ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x53a5a27201158fcf";
        content = {
          type = "gpt";
          partitions = {
            efi = {
              type = "EF00";
              # Maybe someday uuids will work (they failed for me). Could generate with `uuidgen -r`
              name = "main-efi-boot";
              label = "main-efi-boot";
              start = "1M";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "16G";
              name = "main-swap";
              label = "main-swap";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            # will probably need to figure out how to unlock multiple luks devices on initrd
            # (or have luks span device) (or store key for new devices on this device)
            luks = {
              name = "main-luks";
              label = "main-luks";
              size = "100%";
              content = {
                type = "luks";
                name = "main-luks";
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
                  pool = zfsRootPool;
                };
              };
            };
          };
        };
      };
    };
    # Might need activation script for second pool: https://github.com/nix-community/disko/issues/359
    zpool = {
      ${zfsRootPool} = {
        type = "zpool";
        # mode = "mirror";
        rootFsOptions = {
          # These are inherited to all child datasets as the default value
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
          # Might have an issue with neededForUsers needing to be set on filesystem
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
            # Create a blank snapshot of root on creation (if it doesn't exist)
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^${zfsRootPool}/root@blank$' || zfs snapshot ${zfsRootPool}/root@blank";
          };
          # Everything below will be persisted
          "root/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              # Don't use access time for nix store
              atime = "off";
            };
          };
          "root/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
          };
          "root/persist/backup" = {
            type = "zfs_fs";
            mountpoint = "/backup";
          };
          "root/persist/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            # postCreateHook = "zfs snapshot zfspool/home@blank";
          };
        };
      };
    };
  };
}
