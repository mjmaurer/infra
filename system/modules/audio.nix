{ pkgs, lib, ... }:
{
  services.pipewire.enable = lib.mkForce false; # Seems to be enabled by default
  services.pulseaudio.enable = true;
  services.pulseaudio.package = pkgs.pulseaudioFull;
}
