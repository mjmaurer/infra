let
  # [1,1] - 18TB
  # NOTE: parity1 no longer exists, it was replaced entirely by this. 
  mediaParityDisk2 = "/dev/disk/by-id/wwn-0x5000cca28456de24"; 
  mediaParityMnt2 = "/mnt/media/parity2";
  mediaParityName2 = "mediaparity2";
in
{
  disko.devices = {
    disk = {
      ${mediaParityName2} = {
        device = mediaParityDisk2;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            disk = {
              name = mediaParityName2;
              label = mediaParityName2;
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = mediaParityMnt2;
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
