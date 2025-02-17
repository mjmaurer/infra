{ config, kanataPkg, pkgs, lib, ... }: {

  imports = [
    ../modules/nix.nix
    ../modules/users.nix
    ../modules/networking.nix
    ../modules/programs.nix
    ../modules/smb-client.nix
    ../modules/crypt.nix

    ../modules/kanata/kanata.nix

    ../modules/sops
  ];

  modules.kanata = {
    enable = true;
    package = kanataPkg;
  };

  time.timeZone = "America/New_York";

  environment = {
    # Permissible shells
    shells = [ pkgs.zsh pkgs.bash ];
    variables = { EDITOR = "nvim"; };
  };

  # fonts.fontDir.enable = true; # DANGER
  fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
