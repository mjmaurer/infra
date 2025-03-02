{
  config,
  kanataPkg,
  pkgs,
  lib,
  ...
}:
{

  # When adding to Darwin when adding here
  imports = [
    ../modules/screen-sharing.nix
    ../modules/steam.nix
  ];
}
