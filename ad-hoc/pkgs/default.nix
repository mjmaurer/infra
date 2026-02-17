{
  pkgs-latest,
  mylib,
  self,
  ...
}:
let
  crypt = import ./crypt { inherit (pkgs-latest) callPackage writeShellApplication lib; };
  insta360 = import ./insta360 { inherit (pkgs-latest) callPackage; };
  colmap = import ./colmap { inherit (pkgs-latest) writeShellApplication colmapWithCuda; };
in
# Call these with `nix run ~/infra#pkg-name`
{
  # xpo = pkgs.callPackage ./xpo { };
  build-live-iso = pkgs-latest.callPackage ./build-live-iso.nix { };

}
// crypt
// insta360
// colmap
