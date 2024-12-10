{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.karabiner;
in
{
  options.modules.karabiner = {
    enable = lib.mkEnableOption "karabiner";

    justConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "If true, only copy the config files without installing the package. For packages installed external to Nix.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = if cfg.justConfig then [ ] else [ pkgs.karabiner ];

    xdg.configFile = {
      "karabiner/karabiner.json" = {
        source = ./karabiner.json;
      };
    };
  };
}
