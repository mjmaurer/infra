{ pkgs, ... }:

{
  imports = [ ../common/common.nix ../common/common-linux.nix ];

  home.username = pkgs.lib.mkForce "mmaurer7";

  programs.bash.sessionVariables = {
    MACHINE_NAME = "lenovo";
  };
}
