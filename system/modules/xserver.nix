{ ... }:
{
  # NOTE: Xserver (and this module) is currently unused.
  # Nix unfortunately uses "services.xserver" for some wayland
  # configuration for legacy reasons
  services.xserver = {
    enable = true;
    autorun = false;
    desktopManager.plasma5 = {
      enable = true;
    };
    displayManager.lightdm.enable = true;
  };
}
