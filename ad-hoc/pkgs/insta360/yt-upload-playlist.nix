{
  stdenv,
  lib,
  makeWrapper,
  youtubeuploader,
}:

stdenv.mkDerivation rec {
  pname = "yt-upload-playlist";
  version = "0.1.0";

  src = ./yt-upload-playlist.sh;

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -D -m 755 $src $out/bin/yt-upload-playlist
    wrapProgram $out/bin/yt-upload-playlist \
      --prefix PATH : "${lib.makeBinPath [ youtubeuploader ]}"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Upload all MP4 videos in a directory to a new private YouTube playlist";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
