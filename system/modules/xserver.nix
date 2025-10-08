{ config, lib, ... }:
{
  # Nix unfortunately uses "services.xserver" for some wayland
  # configuration for legacy reasons.
  # Xserver is just needed for lightdm and XWayland I believe.
  # Xwayland is currently installed via home-manager
  services.xserver = {
    enable = true;
    autorun = false;
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
