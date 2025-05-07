{ ... }:
{
  # Nix unfortunately uses "services.xserver" for some wayland
  # configuration for legacy reasons.
  # Xserver is just needed for lightdm and XWayland I believe.
  # Xwayland is currently installed via home-manager
  services.xserver = {
    enable = true;
    autorun = false;
    displayManager.lightdm = {
      enable = true;
      greeters.gtk.enable = true;
    };
  };
}
