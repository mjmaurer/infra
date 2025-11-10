{
  imports = [
    ../common/nixos.nix
    ../modules/nix.nix
    ../modules/basic.nix
    ../modules/users.nix
    ../modules/networking.nix
    ../modules/ssh.nix
  ];

  config = {
    swapDevices = [
      {
        device = "/swapfile";
        size = 4096;
      }
    ];

    modules.users.minimalInstall = true;
    modules.networking.minimalInstall = true;
  };
}
