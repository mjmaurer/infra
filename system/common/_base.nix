{ config, pkgs, lib, ... }:
{

  imports = [
    ../modules/nix.nix
  ];

  time.timeZone = "America/New_York";

  environment = {
    # Permissible shells
    shells = [ pkgs.zsh pkgs.bash ];
    variables.EDITOR = "nvim";
  };

  # fonts.fontDir.enable = true; # DANGER
  fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
