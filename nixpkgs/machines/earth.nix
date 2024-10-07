{ pkgs, ... }:

{
  imports = [ ../common/linux.nix ];

  modules = {
    duplicacy.enable = true;
  };

  programs.bash.sessionVariables = {
    MACHINE_NAME = "earth";
  };
}
