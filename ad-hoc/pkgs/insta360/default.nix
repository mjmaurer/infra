{ callPackage }:

rec {
  insta360-media-sdk = callPackage ./insta360-media-sdk.nix { };
  insv2eq = callPackage ./insv2eq.nix { inherit insta360-media-sdk; };
  yt-upload-playlist = callPackage ./yt-upload-playlist.nix { };
}
