{
  ...
}:
{
  imports = [
    ../../modules/disko-common.nix
  ];

  config = {
    modules.disko-common.mainDiskId = "/dev/disk/by-id/wwn-0x53a5a27201158fcf";
  };
}
