{
  lib,
  config,
  ...
}:
let
  cfg = config.modules.disko-common;
  impermEnabled =
    builtins.hasAttr "impermanence" config.modules && config.modules.impermanence.enabled;
in
{
  options.modules.disko-common = {
    enable = lib.mkEnableOption "disko-common";

    # -------------------------------- Required --------------------------------
    mainDiskId = lib.mkOption {
      type = lib.types.str;
      description = "ls -l /dev/disk/by-id/";
    };

    # -------------------------------- Optional --------------------------------
    zfsRootPool = lib.mkOption {
      type = lib.types.str;
      default = "zroot";
    };
  };
  config = {

    fileSystems = lib.mkIf impermEnabled {
      "${config.modules.impermanence.impermanenceMntPath}".neededForBoot = true;
    };

    # Configure the ZFS rollback on boot
    boot.initrd.postDeviceCommands = lib.mkIf impermEnabled (
      lib.mkAfter ''
        zfs rollback -r ${cfg.zfsRootPool}/root@blank
      ''
    );

    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = cfg.mainDiskId;
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
                    pool = cfg.zfsRootPool;
                  };
                };
              };
            };
          };
        };
      };
      # Might need activation script for second pool: https://github.com/nix-community/disko/issues/359
      zpool = {
        ${cfg.zfsRootPool} = {
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
              postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^${cfg.zfsRootPool}/root@blank$' || zfs snapshot ${cfg.zfsRootPool}/root@blank";
            };
            # ------------------- Everything below will be persisted -------------------
            "root/nix" = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options = {
                # Don't use access time for nix store
                atime = "off";
              };
            };
            # Home directory is permanent by default
            "root/home" = {
              type = "zfs_fs";
              mountpoint = "/home";
            };
            # Files not otherwise included in a dataset are impermanent.
            # impermanence.nix will persist marked files / directories to one
            # of these two datasets.
            "root/impermanence" = lib.mkIf impermEnabled {
              type = "zfs_fs";
              mountpoint = config.modules.impermanence.impermanenceMntPath;
            };
          };
        };
      };
    };
  };
}
