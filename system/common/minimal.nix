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
    modules.users.minimalInstall = true;
    modules.networking.minimalInstall = true;
  };
}
