{ config, pkgs, ... }:

{
  imports = [ ./_base.nix ];

  home.packages = with pkgs; [
    google-chrome
    vscode
  ];

  # services = {
  #   gpg-agent = {
  #     enable = true;
  #     pinentryFlavor = "gtk2";
  #   };
  # };
}
