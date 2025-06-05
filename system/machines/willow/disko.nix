{
  ...
}:
{
  imports = [
    ../../modules/disko-common.nix
  ];

  config = {
    modules.disko-common.mainDiskId = "/dev/disk/by-id/nvme-eui.0025385151405c66";

    # Monitoring SAS drives (ie for smfc)
    # services.smartd = {
    #   enable = true;
    #   devices = [
    #     {
    #       device = "/dev/disk/by-id/ata-WDC-XXXXXX-XXXXXX"; # FIXME: Change this to your actual disk
    #     }
    #   ];
    # };
  };
}
