{ pkgs, self, ... }:
let
  crypt = import ./crypt { inherit (pkgs) callPackage writeShellApplication lib; };
  insta360 = import ./insta360 { inherit (pkgs) callPackage; };
  colmap = import ./colmap { inherit (pkgs) writeShellApplication colmapWithCuda; };
in
{
  # xpo = pkgs.callPackage ./xpo { };
  build-live-iso = pkgs.callPackage ./build-live-iso.nix { };

}
// crypt
// insta360
// colmap
