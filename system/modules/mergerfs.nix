{
  lib,
  config,
  derivationName,
  pkgs,
  ...
}:
let
  cfg = config.modules.mergerfs;
in
{
  options.modules.mergerfs = {
    enable = lib.mkEnableOption "Enable MergerFS for pooling filesystems";
    mntPath = lib.mkOption {
      type = lib.types.str;
      description = "The mount path for the MergerFS pool";
      example = "/media";
    };
    diskMnts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of disk mount points to be pooled by MergerFS";
      example = [
        "/mnt/media/disk1"
        "/mnt/media/disk2"
        "/mnt/media/disk3"
      ];
    };
    diskMntGlob = lib.mkOption {
      type = lib.types.str;
      description = "Glob pattern for the disks to be pooled by MergerFS";
      example = "/mnt/media/disk*";
    };
    fsName = lib.mkOption {
      type = lib.types.str;
      description = "Name of the MergerFS filesystem";
    };
    options = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "defaults"
        "cache.files=off"
        "minfreespace=100G"
        # Existing path, most free space
        # Requires that the drives have the same high level paths
        "category.create=epmfs"
        # if the chosen drive fills up mid-write,
        # automatically move the growing file to the emptiest drive instead of erroring out.
        "moveonenospc=true"
      ];
      description = "Mount options for MergerFS";
    };
  };

  config = {
    environment.systemPackages = [
      pkgs.mergerfs
    ];

    fileSystems.${cfg.mntPath} = {
      device = cfg.diskMntGlob;
      fsType = "mergerfs";
      depends = cfg.diskMnts;
      options = cfg.options ++ [
        "fsname=${cfg.fsName}"
      ];
    };
  };
}
