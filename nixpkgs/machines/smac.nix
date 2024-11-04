{ pkgs, ... }:

{
  imports = [ ../common/mac.nix ];

  services.gpg-agent.enable = false;

  home.username = pkgs.lib.mkForce "mmaurer7";
  home.stateVersion = "22.05";


  modules.commonShell = {
    machineName = "smac";
  };
}
