{
  config,
  lib,
  pkgs,
  derivationName,
  username,
  ...
}:
{
  users.groups = {
    content = { };
    rents = { };
    usen = { };
  };

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
      d1 = "/mnt/media/disk1";
      d2 = "/mnt/media/disk2";
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
    diskMnts = [
      "/mnt/media/disk1"
      "/mnt/media/disk2"
      # "/mnt/media/disk3"
    ];
    diskMntGlob = "/mnt/media/disk*";
    ensurePaths = [
      {
        paths = [
          "content"
          "content/movies"
          "content/tv"
          "content/metadata"
          "content/transcode"
        ];
        group = "content";
      }
      {
        paths = [
          "rents"
          "rents/movies"
          "rents/tv"
        ];
        group = "rents";
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
        group = "usen";
      }
    ];
  };
}
