{ pkgs, ... }:

{
  imports = [ ../common/mac.nix ];

  services.ssh-agent.enable = false;

  modules = {
    git.signingKey = "A4F1C5EDE184F6AD";
    commonShell = {
      machineName = "airmac";
    };
  };
}
