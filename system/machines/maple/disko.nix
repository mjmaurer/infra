{ ... }:
let
  zfsPoolName = "zroot";
in
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
              # Generate with `uuidgen -r`
              uuid = "4493CF2E-7EB5-4D7C-BFD9-717DDBA20009";
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
              uuid = "4457A311-2DA8-4B48-BB13-991016CE313E";
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
              uuid = "0F868E8B-F65B-4E39-810D-637F235176EF";
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
                  pool = zfsPoolName;
                };
              };
            };
          };
        };
      };
    };
    # Might need activation script for second pool: https://github.com/nix-community/disko/issues/359
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
