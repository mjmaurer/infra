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
    torrents = { };
    usenet = { };
  };

  modules.mergerfs = {
    enable = true;
    fsName = "media";
    mntPath = "/media";
    diskMnts = [
      "/mnt/media/disk1"
      # "/mnt/media/disk2"
      # "/mnt/media/disk3"
    ];
    diskMntGlob = "/mnt/media/disk*";
    ensurePaths = [
      {
        paths = [
          "content/movies"
          "content/tv"
          "content/metadata"
          "content/transcode"
        ];
        group = "content";
      }
      {
        paths = [
          "torrents/movies"
          "torrents/tv"
        ];
        group = "torrents";
      }
      {
        paths = [
          "usenet/complete/movies"
          "usenet/complete/tv"
          "usenet/incomplete/movies"
          "usenet/incomplete/tv"
          "usenet/history"
        ];
        group = "usenet";
      }
    ];
  };
}
