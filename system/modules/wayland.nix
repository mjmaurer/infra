{
  config,
  lib,
  pkgs,
  ...
}:
{
  # imports = [ ./screen-sharing.nix ];
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      # NVIDIA/GBM + wlroots stability/perf
      # newly added from ll
      export WLR_RENDERER=vulkan
      export WLR_NO_HARDWARE_CURSORS=1
      export GBM_BACKEND=nvidia-drm
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
    '';
  };
  # Xwayland for X11 apps under Sway
  programs.xwayland.enable = config.services.xserver.enable;
  # Required for sway
  security.polkit.enable = true;
  environment.loginShellInit =
    let
      hasNvidia = lib.hasAttrByPath [ "modules" "nvidia" ] config;
    in
    ''
      if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
            sway${lib.optionalString hasNvidia " --unsupported-gpu"} -V > ~/.local/state/sway/sway.log 2>&1
      fi
    '';
}
