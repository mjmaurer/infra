{ pkgs, ... }:

{
  imports = [ ../common/common.nix ../common/common-linux.nix ];

  programs.bash.sessionVariables = {
    MACHINE_NAME = "bobby";
    RVC_PORT = 7865;
  };
}
