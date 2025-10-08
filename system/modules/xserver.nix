{ config, lib, ... }:
{
  # Nix unfortunately uses "services.xserver" for some wayland
  # configuration for legacy reasons.
  services.xserver = {
    enable = true;
    # Xserver is just needed for lightdm and XWayland I believe.
    autorun = true;
    displayManager =
      let
        hasNvidia = lib.hasAttrByPath [ "modules" "nvidia" ] config;
      in
      {
        # This was recently added:
        defaultSession = lib.mkIf (config.programs.sway.enable) "sway";
        lightdm = {
          enable = !hasNvidia;
          greeters.gtk.enable = !hasNvidia;
        };
      };
  };
}
