{ pkgs, ... }:

{
  imports = [ ../common/mac.nix ];

  services.gpg-agent.enable = false;

  home.username = pkgs.lib.mkForce "mmaurer7";

  modules.commonShell = {
    machineName = "smac";
    dirHashes = {
      box = "$HOME/Library/CloudStorage/Box-Box/";
    };
  };
}
