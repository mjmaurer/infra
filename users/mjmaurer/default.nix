{ nix-colors }: { pkgs, config, ... }:
{
  imports = [
    ./common/nixos.nix
    nix-colors.homeManagerModule
    ./wayland.nix
  ];
  colorScheme = nix-colors.colorSchemes.stella;

  home.stateVersion = "24.05";
}
