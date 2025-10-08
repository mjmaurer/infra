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
            sway${lib.optionalString hasNvidia " --unsupported-gpu"} -V > .sway-log 2>&1
      fi
    '';
}
