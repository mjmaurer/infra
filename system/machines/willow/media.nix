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
          "torrents"
          "torrents/movies"
          "torrents/tv"
        ];
        group = "torrents";
      }
      {
        paths = [
          "usenet"
          "usenet/complete"
          "usenet/complete/movies"
          "usenet/complete/tv"
          "usenet/incomplete"
          "usenet/incomplete/movies"
          "usenet/incomplete/tv"
          "usenet/history"
        ];
        group = "usenet";
      }
    ];
  };
}
