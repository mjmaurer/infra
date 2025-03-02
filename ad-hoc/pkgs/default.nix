{ pkgs, self, ... }:
let
  crypt = import ./crypt { inherit (pkgs) callPackage writeShellApplication lib; };
in
{
  # xpo = pkgs.callPackage ./xpo { };
  build-live-iso = pkgs.callPackage ./build-live-iso.nix { };

}
// crypt
