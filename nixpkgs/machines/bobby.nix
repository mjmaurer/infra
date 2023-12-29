{ config, pkgs, ... }:

{
  imports = [ ../common/common.nix ../common/common-linux.nix ];

  programs.bash.sessionVariables = {
    MACHINE_NAME = "bobby";
    RVC_PORT = 7865;
    DEPLOY_SHARED_MOUNT = "${config.home.homeDirectory}/deploy/shared-data";
    DEPLOY_MODELS_MOUNT = "${config.home.homeDirectory}/deploy/models";
  };
}
