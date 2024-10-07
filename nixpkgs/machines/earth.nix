{ pkgs, ... }:

{
  imports = [ ../common/linux.nix ];

  modules = {
    duplicacy.enable = true;
    commonShell.machineName = "earth";
  };

}
