{
  stdenv,
  lib,
  requireFile,
  dpkg,
  autoPatchelfHook,
  libGL,
  libglvnd,
  mesa,
  vulkan-loader,
  cudaPackages,
  zlib,
  libpng,
  xorg,
  wayland,
  libdrm,
}:

stdenv.mkDerivation (
  let
    modelFilesSrc = requireFile {
      name = "insta360-modelfiles.tar.gz";
      sha256 = "1hpnhrrkvffb2925dw9y9ih28xacqr2sc6l2cj8zkd6fygly0skv";
      message = ''
        Please add the Insta360 model files to the Nix store:

        1. Create the tar archive:
           tar -czf /tmp/insta360-modelfiles.tar.gz -C /nas/content/code/sdks/insta360mediasdk/libMediaSDK-dev-3.0.5.1-20250618_195946-amd64 modelfile

        2. Get the sha256 hash (for verification):
           nix hash file --type sha256 --base32 /tmp/insta360-modelfiles.tar.gz
           Expected: 0f12bgvvakm1zy6dk6x0hp8ir79xfkj3lih9k9hbwj2866bvg8rr

        3. Add to Nix store (run from /tmp directory):
           nix-store --add-fixed sha256 /tmp/insta360-modelfiles.tar.gz

        Then try building again.
      '';
    };
  in
  {
    pname = "insta360-media-sdk";
    version = "3.0.5.1";

    src = requireFile {
      name = "libMediaSDK-dev-3.0.5.1-20250618_195946-amd64.deb";
      sha256 = "907440d96540e949a27dab489357f5aeee5f3cfc5f6011c3d1e6dc428f783421";
      message = ''
        Please add the Insta360 Media SDK .deb file to the Nix store:

        nix-store --add-fixed sha256 /nas/content/code/sdks/insta360mediasdk/libMediaSDK-dev-3.0.5.1-20250618_195946-amd64/libMediaSDK-dev-3.0.5.1-20250618_195946-amd64.deb

        Then try building again.
      '';
    };

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
    ];

    buildInputs = [
      libGL
      libglvnd
      mesa
      vulkan-loader
      cudaPackages.cudatoolkit
      stdenv.cc.cc.lib
      zlib
      libpng
      xorg.libX11
      xorg.libXext
      wayland
      libdrm
    ];

    unpackPhase = ''
      # Extract the .deb file
      dpkg-deb -x $src .

      # Extract the model files
      tar -xzf ${modelFilesSrc}
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

      # Copy model files from extracted archive
      if [ -d modelfile ]; then
        cp -r modelfile $out/
      else
        echo "Error: Model files not found in extracted archive"
        exit 1
      fi
    '';

    meta = with lib; {
      description = "Insta360 Media SDK for Linux";
      platforms = platforms.linux;
    };
  }
)
