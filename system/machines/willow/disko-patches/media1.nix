let
  # [1,2]
  mediaDisk1 = "/dev/disk/by-id/wwn-0x5000c500869bbf27";
  # TODO: So because disko sets rootMountPoint to /mnt during `disko run`,
  # this is mounted to /mnt/mnt/media1 instead of /mnt/media1 (I think to resolve issues during installation)
  # This is rectified during boot, but the directories aren't cleaned up.
  # Could override
  mediaMnt1 = "/mnt/media/disk1";
  # [1,3]
  mediaDisk2 = "/dev/disk/by-id/wwn-0x5000c50085565ddb";
  mediaMnt2 = "/mnt/media/disk2";
in
{
  disko.devices = {
    disk = {
      media1 = {
        device = mediaDisk1;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            disk = {
              name = "media1";
              label = "media1";
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = mediaMnt1;
                mountOptions = [
                  "defaults"
                  "nofail"
                  # "pquota"
                ];
              };
            };
          };
        };
      };
      media2 = {
        device = mediaDisk2;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            disk = {
              name = "media2";
              label = "media2";
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = mediaMnt2;
                mountOptions = [
                  "defaults"
                  "nofail"
                  # "pquota"
                ];
              };
            };
          };
        };
      };
    };
  };
}
