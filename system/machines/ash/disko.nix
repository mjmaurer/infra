{
  ...
}:
{
  imports = [
    ../../modules/disko-common.nix
  ];

  config = {
    modules.disko-common.mainDiskId = "/dev/disk/by-id/nvme-eui.002538b331a19f85";
  };
}
