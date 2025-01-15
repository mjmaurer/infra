{ pkgs, ... }:

{
  imports = [ ../common/mac.nix ];

  modules = {
    # git.signingKey = "A4F1C5EDE184F6AD";
    commonShell = {
      machineName = "airmac";
    };
  };
}
