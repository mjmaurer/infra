{ lib, pkgs, ... }: {
  time.timeZone = "America/New_York";
  # ---------------------------------- Fonts ---------------------------------
  # fonts.fontDir.enable = true; # DANGER
  fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

  environment = {
    # Permissible shells
    shells = [ pkgs.zsh pkgs.bash ];
    variables = { EDITOR = "nvim"; };
  };
}
