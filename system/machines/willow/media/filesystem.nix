{
  config,
  lib,
  pkgs,
  derivationName,
  username,
  ...
}:
let
  cfg = config.modules.mediaStack;
in
{
  users.groups = {
    # Generic group that all media services belong to
    ${cfg.groups.general}.gid = 426; # Arbitrary. Needs ID for Docker
    # Probably need to add plex to 'render' group
    ${cfg.groups.content} = { };
    ${cfg.groups.rents} = { };
    ${cfg.groups.usen} = { };
  };

  users.users.${username}.extraGroups = [
    cfg.groups.content
    cfg.groups.rents
    cfg.groups.usen
    cfg.groups.general
  ];

  # NOTE: For some reason, have to run `snapraid sync` outside
  # of systemd for it to create the parity file
  services.snapraid = {
    enable = true;
    sync.interval = "Tue,Fri *-*-* 03:00:00 America/New_York";
    scrub.interval = "Wed *-*-* 03:00:00 America/New_York";
    parityFiles = [
      "/mnt/media/parity1/snapraid.parity"
    ];
    # Content files are used to track which files are in the snapraid pool
    # Choose three for backups purposes
    contentFiles = [
      "/var/snapraid.content"
      "/mnt/media/disk1/d1-snapraid.content"
      "/mnt/media/disk2/d2-snapraid.content"
    ];
    dataDisks = {
      d1 = "/mnt/media/disk1/";
      d2 = "/mnt/media/disk2/";
    };
    exclude = [
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
      "downloads/"
      "appdata/"
      "*.!sync"
      "/.snapshots/"
    ];
  };

  modules.mergerfs = {
    enable = true;
    fsName = "media";
    mntPath = "/media";
    extraOptions = [
      "umask=0007"
    ];
    diskMnts = [
      "/mnt/media/disk1"
      "/mnt/media/disk2"
      # "/mnt/media/disk3"
    ];
    diskMntGlob = "/mnt/media/disk*";
    ensurePaths = [
      {
        paths = [ "." ];
        owner = "root";
        group = cfg.groups.general;
      }
      {
        paths = [
          "content"
          "content/movies"
          "content/tv"
          "content/metadata"
          "content/transcode"
        ];
        group = cfg.groups.content;
      }
      {
        paths = [
          "rents"
          "rents/movies"
          "rents/tv"
        ];
        group = cfg.groups.rents;
      }
      {
        paths = [
          "usen"
          "usen/complete"
          "usen/complete/movies"
          "usen/complete/tv"
          "usen/incomplete"
          "usen/incomplete/movies"
          "usen/incomplete/tv"
          "usen/history"
        ];
        group = cfg.groups.usen;
      }
    ];
  };
}
