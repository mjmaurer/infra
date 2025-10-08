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
        lib.types.listOf (
          lib.types.submodule {
            options = {
              paths = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "Relative paths to ensure on each disk";
                example = lib.literalExpression ''[ "media/movies", "media/tv_shows" ]'';
              };
              owner = lib.mkOption {
                type = lib.types.str;
                default = config.users.users.${username}.name;
                description = "Owner of the path";
              };
              group = lib.mkOption {
                type = lib.types.str;
                default = config.users.groups.${username}.name;
                description = "Group of the path";
              };
              mode = lib.mkOption {
                type = lib.types.str;
                # SetGID (inherit group), User (rwx), Group (rwx), Others (---)
                default = "2770";
                description = "Permissions mode for the path (e.g., '2770' for rwxrwx---)";
              };
            };
          }
        )
      );
      default = null;
      description = "List of path configurations to ensure exist on each disk defined in diskMnts. Each configuration specifies a list of paths and their shared owner, group, and mode.";
    };
    options = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "defaults"
        "allow_other"
        "default_permissions"
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
    extraOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra mount options for MergerFS";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.mergerfs
    ];

    fileSystems.${cfg.mntPath} = {
      device = cfg.diskMntGlob;
      fsType = "mergerfs";
      depends = cfg.diskMnts;
      options =
        cfg.options
        ++ cfg.extraOptions
        ++ [
          "fsname=${cfg.fsName}"
        ];
    };

    # Can debug with:
    # SYSTEMD_LOG_LEVEL=debug systemd-tmpfiles --create
    systemd.tmpfiles.settings = lib.mkIf (cfg.ensurePaths != null) {
      "mergerfs-ensure-paths" = lib.listToAttrs (
        lib.concatMap (
          diskMnt:
          lib.concatMap (
            pathConfig:
            lib.map (
              relativePath:
              let
                fullPath = "${diskMnt}/${relativePath}";
              in
              lib.nameValuePair fullPath {
                d = {
                  user = pathConfig.owner;
                  group = pathConfig.group;
                  mode = pathConfig.mode;
                };
              }
            ) pathConfig.paths
          ) cfg.ensurePaths
        ) cfg.diskMnts
      );
    };
  };
}
