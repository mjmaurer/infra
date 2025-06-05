{
  ...
}:
{
  imports = [
    ../../modules/disko-common.nix
  ];

  config = {
    modules.disko-common.mainDiskId = "/dev/disk/by-id/nvme-eui.0025385151405c66";
  };
}
