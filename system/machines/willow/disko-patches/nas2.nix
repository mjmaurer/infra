let
  nasDisk2 = "/dev/disk/by-id/";
  nasPoolName = "znas";
in
{
  disko.devices = {
    disk = {
      nas2 = {
        device = nasDisk2;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              name = "nas2-luks";
              label = "nas2-luks";
              size = "100%";
              content = {
                type = "luks";
                name = "nas2-luks";
                extraFormatArgs = [
                  "--pbkdf argon2i"
                  "--use-random"
                ];
                initrdUnlock = true;
                extraOpenArgs = [ "--allow-discards" ];
                passwordFile = "/tmp/disk.key";
                content = {
                  type = "zfs";
                  pool = nasPoolName;
                };
              };
            };
          };
        };
      };
    };
  };
}
