{ pkgs, lib, ... }:
let
  sdkPath = "/nas/content/code/sdks/insta360mediasdk/libMediaSDK-dev-3.0.5.1-20250618_195946-amd64/libMediaSDK-dev-3.0.5.1-20250618_195946-amd64.deb";

  # Extract the Insta360 Media SDK from the deb package
  insta360-media-sdk = pkgs.stdenv.mkDerivation rec {
    pname = "insta360-media-sdk";
    version = "3.0.5.1";

    src = pkgs.fetchurl {
      url = "file://${sdkPath}";
      sha256 = "YOUR_SHA256_HASH_HERE";
    };

    nativeBuildInputs = with pkgs; [
      dpkg
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
    '';

    meta = with lib; {
      description = "Insta360 Media SDK";
      platforms = platforms.linux;
    };
  };

  # Build the insv2eq tool using the extracted SDK
  insv2eq = pkgs.stdenv.mkDerivation {
    pname = "insv2eq";
    version = "0.1";

    src = ./.;

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
    ];

    buildInputs = with pkgs; [
      gcc17
      cxxopts
      ffmpeg
      vulkan-loader
      cudaPackages.cudatoolkit
      insta360-media-sdk
    ];

    # Set up environment for finding the SDK
    MEDIASDK_ROOT = "${insta360-media-sdk}";

    # Create a simple CMakeLists.txt if it doesn't exist
    preConfigure = ''
            if [ ! -f CMakeLists.txt ]; then
              cat > CMakeLists.txt << 'EOF'
      cmake_minimum_required(VERSION 3.10)
      project(insv2eq)

      set(CMAKE_CXX_STANDARD 17)

      # Find required packages
      find_package(PkgConfig REQUIRED)
      find_package(cxxopts REQUIRED)
      pkg_check_modules(FFMPEG REQUIRED libavformat libavcodec libavutil libswscale)

      # Set MediaSDK paths
      set(MEDIASDK_ROOT "$ENV{MEDIASDK_ROOT}")
      if(NOT MEDIASDK_ROOT)
        message(FATAL_ERROR "MEDIASDK_ROOT environment variable not set")
      endif()

      # Add executable
      add_executable(insv2eq insv2eq.cpp)

      # Include directories
      target_include_directories(insv2eq PRIVATE
        ''${MEDIASDK_ROOT}/include
        ''${cxxopts_INCLUDE_DIRS}
        ''${FFMPEG_INCLUDE_DIRS}
      )

      # Link libraries
      target_link_directories(insv2eq PRIVATE
        ''${MEDIASDK_ROOT}/lib
      )

      target_link_libraries(insv2eq
        ins_media_sdk
        ''${FFMPEG_LIBRARIES}
        pthread
        dl
      )

      # Set rpath for runtime
      set_target_properties(insv2eq PROPERTIES
        INSTALL_RPATH "''${MEDIASDK_ROOT}/lib"
        INSTALL_RPATH_USE_LINK_PATH TRUE
      )

      install(TARGETS insv2eq DESTINATION bin)
      EOF
            fi
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp insv2eq $out/bin/

      # Ensure the binary can find the SDK libraries at runtime
      patchelf --set-rpath "${insta360-media-sdk}/lib:$(patchelf --print-rpath $out/bin/insv2eq)" $out/bin/insv2eq || true
    '';
  };
in
{
  home.packages = lib.optional (builtins.pathExists sdkPath) insv2eq;
}
