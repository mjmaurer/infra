{ config, lib, ... }:
let
  hasNvidia = lib.hasAttrByPath [ "modules" "nvidia" ] config;
in
{
  # Nix unfortunately uses "services.xserver" for some wayland
  # configuration for legacy reasons.
  services.xserver = {
    enable = true;
    # Xserver is just needed for lightdm and XWayland I believe.
    autorun = hasNvidia;
    displayManager = {
      lightdm = {
        enable = !hasNvidia;
        greeters.gtk.enable = !hasNvidia;
      };
    };
  };
  services.displayManager.defaultSession = lib.mkIf (config.programs.sway.enable) "sway";
}
