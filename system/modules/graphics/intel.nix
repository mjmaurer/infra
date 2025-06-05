{ pkgs, ... }:
{
  # Might overlap with community provided common skylake options here:
  # https://github.com/NixOS/nixos-hardware/tree/master/common/gpu/intel

  environment = {
    systemPackages = [
      # To enable `intel_gpu_top`
      pkgs.intel-gpu-tools
    ];
    #  (See `hardware.graphics` below) Force use of iHD driver, but Nix says Skylake has trouble.
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    }; # or 'i965'
  };

  boot.kernelModules = [ "coretemp" ];

  hardware = {
    # Should be set in hardware-configuration.nix:
    # cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware; Should be set in hardware-configuration.nix

    # https://download.lenovo.com/parts/ThinkCentre/m700_tiny_overview.pdf
    # (Skylake)
    # https://www.intel.com/content/www/us/en/products/sku/88183/intel-core-i56500t-processor-6m-cache-up-to-3-10-ghz/specifications.html
    # https://nixos.wiki/wiki/Intel_Graphics
    # https://nixos.wiki/wiki/Accelerated_Video_Playback
    # Good intel media stack wiki: https://github.com/intel/media-driver/wiki
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        # Older driver for fallback (previously vaapiIntel):
        intel-vaapi-driver # LIBVA_DRIVER_NAME=i965
        # Newer driver:
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        # Even newer (previously onevpl-intel-gpu)
        # See here for when to to use this vs media-driver:
        # https://github.com/intel/libvpl?tab=readme-ov-file#dispatcher-behavior-when-targeting-intel-gpus
        vpl-gpu-rt

        # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        intel-compute-runtime

        # Don't think I need these:
        # See https://wiki.archlinux.org/title/Hardware_video_acceleration#Verification
        # vaapiVdpau # think VDPAU is just for nvidia
        # libvdpau-va-gl # compat layer that translates VDPAU calls to VA-API (va-api is natively supported by quicksync)
      ];
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    # Hybrid driver might provide VP9 for skylake, but this was also archived a long time ago.
    # Probably don't need VP9 (it's video codec), and could comment out if trouble
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };
}
