{ pkgs, ... }:

{
  imports = [ ../common/common.nix ../common/common-linux.nix ../modules/duplicacy/duplicacy.nix ];

  programs.bash.sessionVariables = {
    MACHINE_NAME = "earth";
  };
}
