{ config, pkgs, lib, ... }:
{
  time.timeZone = "America/New_York";

  environment = {
    shells = [ pkgs.zsh pkgs.bash ];
    # Permissible shells
    loginShell = pkgs.zsh;
  };

  # fonts.fontDir.enable = true; # DANGER
  fonts.fonts = [ (pkgs.nerdfonts.override { fonts = [ "Meslo" ]; }) ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
