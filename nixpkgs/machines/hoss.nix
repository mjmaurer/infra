{ pkgs, ... }:

{
  imports = [ ../common/wsl.nix ];

  modules.commonShell = {
    machineName = "hoss";
    sessionVariables = {
      WIN_DOWNLOADS = "/mnt/c/Users/mjmau/Downloads/";
    };
  };
}
