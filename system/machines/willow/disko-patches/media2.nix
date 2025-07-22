let
  # [2,3]
  mediaDisk3 = "/dev/disk/by-id/usb-BR25_UDISK_1120031603090807-0:0";
  mediaDiskName3 = "media3";
  mediaDiskMnt3 = "/mnt/media/disk3";
  # [1,0]
  mediaDisk4 = "/dev/disk/by-id/wwn-0x5000cca260ed767d";
  mediaDiskName4 = "media4";
  mediaDiskMnt4 = "/mnt/media/disk4";
in
{
  disko.devices = {
    disk = {
      ${mediaDiskName3} = {
        device = mediaDisk3;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            disk = {
              name = mediaDiskName3;
              label = mediaDiskName3;
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = mediaDiskMnt3;
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
      ${mediaDiskName4} = {
        device = mediaDisk4;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            disk = {
              name = mediaDiskName4;
              label = mediaDiskName4;
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = mediaDiskMnt4;
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
