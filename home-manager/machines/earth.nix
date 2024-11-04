{ pkgs, ... }:

{
  imports = [ ../common/linux.nix ];

  home.stateVersion = "22.05";

  modules = {
    duplicacy.enable = true;
    commonShell.machineName = "earth";
  };

}
