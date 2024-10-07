{ pkgs, ... }:

{
  imports = [ ../common/linux.nix ../modules/duplicacy/duplicacy.nix ];

  programs.bash.sessionVariables = {
    MACHINE_NAME = "earth";
  };
}
