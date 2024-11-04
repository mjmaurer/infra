{ pkgs, ... }:

{
  imports = [ ../common/linux.nix ];

  home.username = "mmaurer7";
  home.stateVersion = "22.05";

  modules.commonShell.machineName = "lenovo";
}
