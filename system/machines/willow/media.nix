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
