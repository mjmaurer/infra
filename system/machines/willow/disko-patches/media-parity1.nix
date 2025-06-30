let
  # [1,0]
  mediaParityDisk1 = "/dev/disk/by-id/wwn-0x5000cca260ed767d";
  mediaParityMnt1 = "/mnt/media/parity1";
in
{
  disko.devices = {
    disk = {
      media1 = {
        device = mediaParityDisk1;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            disk = {
              name = "mediaparity1";
              label = "mediaparity1";
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = mediaParityMnt1;
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
