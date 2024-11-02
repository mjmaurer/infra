{ ... }:
{
  services.xserver = {
    enable = true;
    autorun = false;
    desktopManager.plasma6 = {
      enable = true;
    };
    displayManager.lightdm.enable = true;
  };
}
