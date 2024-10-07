{ config, pkgs, ... }:

{
  imports = [ ../common/linux.nix ];

  modules.commonShell = {
    machineName = "bobby";
    sessionVariables = {
      DEPLOY_SHARED_MOUNT = "${config.home.homeDirectory}/deploy/shared-data";
      DEPLOY_MODELS_MOUNT = "${config.home.homeDirectory}/deploy/models";
    };
  };
}
