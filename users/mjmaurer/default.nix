{ nix-colors }: { pkgs, config, ... }:
{
  imports = [
    nix-colors.homeManagerModule
    ./common/programs.nix
    ./wayland.nix
  ];
  colorScheme = nix-colors.colorSchemes.stella;

  home.stateVersion = "24.05";
}
