let
  mediaDisk1 = "/dev/disk/by-id/wwn-0x5000c500869bbf27";
  mediaMnt = "/mnt/media/disk1";
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
                mountpoint = mediaMnt;
                mountOptions = [
                  "defaults"
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
