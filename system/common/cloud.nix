{
  config,
  kanataPkg,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../modules/nix.nix
    ../modules/basic.nix
    ../modules/users.nix
    ../modules/networking.nix
    ../modules/ssh.nix

    ../modules/sops
  ];
}
