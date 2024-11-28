{ pkgs, ... }:

{
  imports = [ ../common/mac.nix ];

  home.username = pkgs.lib.mkForce "mmaurer7";

  services.ssh-agent.enable = false;

  modules = {
    git.signingKey = "33EBB38F3D20DBB8";
    commonShell = {
      machineName = "smac";
      dirHashes = {
        box = "$HOME/Library/CloudStorage/Box-Box/";
      };
    };
  };
}
