{ lib, config, pkgs, ... }:
let
  cfg = config.modules.gpg;
in
{
  options.modules.gpg = {
    enable = lib.mkEnableOption "gpg";
  };

  config = lib.mkIf cfg.enable {
    programs.gpg = {
      enable = true;
    };
    services.gpg-agent = {
      enable = true;
      defaultCacheTtl = 3600;
      maxCacheTtl = 34560000;
      # pinentryFlavor = "qt";
      # enableScDaemon = false;
    };
  };
}
