{
  pkgs,
  lib,
  config,
  ...
}:
let
in
{
  options.modules.nvidia = {
    enableCUDA = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable CUDA support for NVIDIA cards.";
    };
    # Can verify nvlink with `nvidia-smi topo -m`
  };

  config = lib.mkMerge [

    {
      modules.virt.enableNvidia = true;
      # Required for docker, not sure about podman:
      # https://nixos.wiki/wiki/Nvidia#NVIDIA_Docker_not_Working
      # virtualisation.docker.daemon.settings.features.cdi = true;

      # For xorg / wayland
      services.xserver.videoDrivers = [ "nvidia" ];

      environment.systemPackages = with pkgs; [
        # Useful tools for nvidia:
        nvidia-smi
        nvidia-settings # NVIDIA GUI utility
        nvtop # NVIDIA GPU monitoring utility

        glxinfo # from mesa-demos
      ];
      environment.sessionVariables = {
        WLR_NO_HARDWARE_CURSORS = "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        # For VA-API on NVIDIA (Chromium/Firefox/mpv can use this)
        # LIBVA_DRIVER_NAME = "nvidia"; might cause issues in headless
        VDPAU_DRIVER = "nvidia";
      };

      hardware = {
        nvidia-container-toolkit = {
          enable = true;
          mount-nvidia-executables = true;
        };
        nvidia = {
          extraPackages = with pkgs; [
            nvidia-vaapi-driver
            # nv-codec-headers-12
            # nvtopPackages.full

            # Accelerated graphics support for NVIDIA GPUs:
            mesa
            vulkan-tools
            libva-utils
            vdpauinfo
            # May not be needed when using nvidia-vaapi-driver:
            # libvdpau-va-gl
          ];

          # closed-source driver is required for CUDA/NVLink
          # Only supported by: https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
          open = false;
          # NOTE: Probably the thing that will break if anything
          package = config.boot.kernelPackages.nvidiaPackages.stable;

          # needed for Wayland + early-KMS console
          modesetting.enable = true;

          # Enable the Nvidia settings menu,
          # accessible via `nvidia-settings`.
          nvidiaSettings = true;

          # NOTE: Could consider enabling this if headless docker workloads can handle it:
          powerManagement = {
            # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
            # Enable this if you have graphical corruption issues or application crashes after waking
            # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
            # of just the bare essentials.
            # dynamic clocks, etc.
            enable = false;
            # Fine-grained power management. Turns off GPU when not in use.
            # Experimental and only works on modern Nvidia GPUs (Turing or newer).
            finegrained = false;
          };
          # prevents driver unload/reload:
          nvidiaPersistenced = true;
          # controls NVLink topology:
          # fabricmanager = {
          #   enable = true;
          #   # Maybe see: https://github.com/NixOS/nixpkgs/issues/259887
          #   # settings = {};
          # };
        };
        # OpenGL / Vulkan layers and 32-bit support (Steam, Wine)
        opengl = {
          enable = true;
          driSupport = true;
          # driSupport32Bit = true;
          # HW video decode
          extraPackages = with pkgs; [ nvidia-vaapi-driver ];
        };
      };

    }

    (lib.mkIf config.modules.nvidia.enableCUDA {
      programs.cuda.enable = true;

      environment.systemPackages = with pkgs; [
        cudaPackages.cudatoolkit
        cudaPackages.nccl
        cudaPackages.cudnn
        cudaPackages.cutensor
        # cudaPackages.cuda_cudart
        # cudaPackages.cuda_nvcc
        # cudaPackages.cuda_cccl

        # linuxPackages.nvidia_x11
        libGLU
        libGL
        freeglut
        xorg.libXi
        xorg.libXmu
        xorg.libXext
        xorg.libX11
        xorg.libXv
        xorg.libXrandr
      ];
      environment.sessionVariables = rec {
        CUDA_PATH = pkgs.cudaPackages.cudatoolkit;
        CUDA_HOME = pkgs.cudaPackages.cudatoolkit;
      };
      # LD_LIBRARY_PATH=/run/opengl-driver/lib

      nixpkgs.config.cudaSupport = true;
    })
  ];
}
