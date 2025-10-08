{ config, lib, ... }:
{
  # Nix unfortunately uses "services.xserver" for some wayland
  # configuration for legacy reasons.
  # Xserver is just needed for lightdm and XWayland I believe.
  # Xwayland is currently installed via home-manager
  services.xserver = {
    enable = true;
    autorun = false;
    displayManager = {
      # This was recently added: 
      defaultSession = lib.mkIf (config.programs.sway.enable) "sway";
      lightdm = lib.mkIf (!(config.modules ? nvidia)) {
        enable = true;
        greeters.gtk.enable = true;
      };
    };
  };
}
