{ pkgs, ... }:

{
  imports = [ ../common/wsl.nix ];

  modules.commonShell = {
    machineName = "yoga";
    sessionVariables = {
      WIN_DOWNLOADS = "/mnt/c/Users/mjmau/Downloads/";
    };
  };
}
