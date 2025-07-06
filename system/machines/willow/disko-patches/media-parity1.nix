let
  # [1,0]
  mediaParityDisk1 = "/dev/disk/by-id/wwn-0x5000cca260ed767d";
  mediaParityMnt1 = "/mnt/media/parity1";
  mediaParityName1 = "mediaparity1";
in
{
  disko.devices = {
    disk = {
      ${mediaParityName1} = {
        device = mediaParityDisk1;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            disk = {
              name = mediaParityName1;
              label = mediaParityName1;
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
