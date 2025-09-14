{ pkgs, self, ... }:
let
  crypt = import ./crypt { inherit (pkgs) callPackage writeShellApplication lib; };
  insta360 = import ./insta360 { inherit (pkgs) callPackage; };
in
{
  # xpo = pkgs.callPackage ./xpo { };
  build-live-iso = pkgs.callPackage ./build-live-iso.nix { };

}
// crypt
// insta360
