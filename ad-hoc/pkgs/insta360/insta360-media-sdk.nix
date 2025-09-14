{
  stdenv,
  lib,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  libGL,
  vulkan-loader,
  cudaPackages,
}:

stdenv.mkDerivation {
  pname = "insta360-media-sdk";
  version = "3.0.5.1";

  # You'll need to copy the .deb file to this location or update the URL
  src = fetchurl {
    # For now, using a placeholder URL - you'll need to host this file somewhere
    # or copy it to the nix store manually
    url = "file:///nas/content/code/sdks/insta360mediasdk/libMediaSDK-dev-3.0.5.1-20250618_195946-amd64/libMediaSDK-dev-3.0.5.1-20250618_195946-amd64.deb";
    sha256 = "907440d96540e949a27dab489357f5aeee5f3cfc5f6011c3d1e6dc428f783421";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
  ];

  buildInputs = [
    libGL
    vulkan-loader
    cudaPackages.cudatoolkit
    stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out

    # Copy the SDK files to the output
    if [ -d opt/Insta360/MediaSDK ]; then
      cp -r opt/Insta360/MediaSDK/* $out/
    elif [ -d usr ]; then
      cp -r usr/* $out/
    else
      echo "Warning: SDK structure not as expected, copying all files"
      cp -r * $out/
    fi

    # Ensure lib directory exists and has proper structure
    if [ ! -d $out/lib ]; then
      mkdir -p $out/lib
      # If libraries are in a different location, find and move them
      find $out -name "*.so*" -type f -exec mv {} $out/lib/ \; 2>/dev/null || true
    fi

    # Ensure include directory exists
    if [ ! -d $out/include ]; then
      mkdir -p $out/include
      # If headers are in a different location, find and move them
      find $out -name "*.h" -o -name "*.hpp" -type f -exec mv {} $out/include/ \; 2>/dev/null || true
    fi
  '';

  meta = with lib; {
    description = "Insta360 Media SDK for Linux";
    platforms = platforms.linux;
  };
}
