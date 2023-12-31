{ config, pkgs, ... }:

{
  imports = [ ../common/common.nix ../common/common-linux.nix ];

  programs.bash.sessionVariables = {
    MACHINE_NAME = "bobby";
    DEPLOY_SHARED_MOUNT = "${config.home.homeDirectory}/deploy/shared-data";
    DEPLOY_MODELS_MOUNT = "${config.home.homeDirectory}/deploy/models";
  };
}
