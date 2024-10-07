{ pkgs, ... }:

{
  imports = [ ../common/linux.nix ];

  home.username = pkgs.lib.mkForce "mmaurer7";

  modules.commonShell.machineName = "lenovo";
}
