{ pkgs, self, ... }:
{
  # xpo = pkgs.callPackage ./xpo { };
  build-live-iso = pkgs.callPackage ./build-live-iso.nix { };
}
