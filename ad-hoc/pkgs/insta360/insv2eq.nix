{
  stdenv,
  lib,
  cmake,
  pkg-config,
  autoPatchelfHook,
  cxxopts,
  ffmpeg,
  insta360-media-sdk,
  vulkan-loader,
  cudaPackages,
  libGL,
  libglvnd,
  mesa,
  xorg,
  wayland,
  libdrm,
}:

cudaPackages.backendStdenv.mkDerivation rec {
  pname = "insv2eq";
  version = "0.1";

  src = ./.;

  nativeBuildInputs = [
    cmake
    pkg-config
    autoPatchelfHook
  ];

  buildInputs = [
    cxxopts
    ffmpeg
    vulkan-loader
    cudaPackages.cudatoolkit
    insta360-media-sdk
    cudaPackages.backendStdenv.cc.cc.lib
    libGL
    libglvnd
    mesa
    xorg.libX11
    xorg.libXext
    wayland
    libdrm
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
      MediaSDK
      ''${FFMPEG_LIBRARIES}
      pthread
      dl
      stdc++
      m
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

  # Specify runtime library paths for autoPatchelfHook
  runtimeDependencies = [
    insta360-media-sdk
    ffmpeg
    vulkan-loader
    cudaPackages.cudatoolkit
    libGL
    libglvnd
    mesa
    xorg.libX11
    xorg.libXext
    wayland
    libdrm
  ];

  installPhase = ''
        mkdir -p $out/bin
        cp insv2eq $out/bin/insv2eq-unwrapped
        
        # Create wrapper script that sets MEDIASDK_ROOT
        cat > $out/bin/insv2eq << 'EOF'
    #!/bin/bash
    export MEDIASDK_ROOT="${insta360-media-sdk}"
    exec "$0-unwrapped" "$@"
    EOF
        chmod +x $out/bin/insv2eq
  '';

  meta = with lib; {
    description = "Tool to convert Insta360 insp/insv files to equirectangular format";
    platforms = platforms.linux;
    license = licenses.mit;
  };
}
