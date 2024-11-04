{ config, pkgs, ... }:

{
  imports = [ ../common/linux.nix ];

  home.stateVersion = "22.05";

  modules.commonShell = {
    machineName = "bobby";
    sessionVariables = {
      DEPLOY_SHARED_MOUNT = "${config.home.homeDirectory}/deploy/shared-data";
      DEPLOY_MODELS_MOUNT = "${config.home.homeDirectory}/deploy/models";
    };
  };
}
