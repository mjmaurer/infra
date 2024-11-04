{ pkgs, ... }:

{
  imports = [ ../common/wsl.nix ];

  home.stateVersion = "22.05";

  modules.commonShell = {
    machineName = "yoga";
    sessionVariables = {
      WIN_DOWNLOADS = "/mnt/c/Users/mjmau/Downloads/";
    };
  };
}
