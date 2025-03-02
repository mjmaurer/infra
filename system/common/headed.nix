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
    ./headed-minimal.nix

    ../modules/screen-sharing.nix
    ../modules/steam.nix
  ];
}
