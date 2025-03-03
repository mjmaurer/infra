{ pkgs, lib, ... }:
{
  services.pipewire.enable = lib.mkForce false; # Seems to be enabled by default
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
}
