{ pkgs, ... }:

{
  imports = [ ../common/common.nix ../common/common-wsl.nix ];
  programs.bash.sessionVariables = {
    MACHINE_NAME = "hoss";
    WIN_DOWNLOADS = "/mnt/c/Users/mjmau/Downloads/";
  };
}
