{
  lib,
  config,
  username,
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
    ensurePaths = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule (
          { config, ... }:
          {
            paths = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "List of paths to ensure exist on each disk defined in diskMnts";
              example = [
                "media/movies"
                "media/tv"
              ];
            };
            owner = lib.mkOption {
              type = lib.types.str;
              default = config.users.users.${username}.name;
              description = "Owner of the paths to ensure";
            };
            group = lib.mkOption {
              type = lib.types.str;
              default = config.users.groups.${username}.name;
              description = "Group of the paths to ensure";
            };
            mode = lib.mkOption {
              type = lib.types.str;
              default = "0755";
              description = "Permissions mode for the ensured paths (e.g., 0755)";
            };
          }
        )
      );
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

    systemd.tmpfiles.settings = lib.mkIf (cfg.ensurePaths != null) {
      "mergerfs-ensure-paths" = lib.listToAttrs (
        lib.concatMap (
          diskMnt:
          lib.map (
            relativePath:
            let
              fullPath = "${diskMnt}/${relativePath}";
            in
            lib.nameValuePair fullPath {
              d = {
                user = cfg.ensurePaths.owner;
                group = cfg.ensurePaths.group;
                mode = cfg.ensurePaths.mode;
              };
            }
          ) cfg.ensurePaths.paths
        ) cfg.diskMnts
      );
    };
  };
}
