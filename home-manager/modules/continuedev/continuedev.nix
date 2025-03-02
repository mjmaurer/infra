{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.continuedev;
in
{
  options.modules.continuedev = {
    enable = lib.mkEnableOption "continuedev";

    justConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "[NOOP currently] If true, only copy the config files without installing the package. For packages installed external to Nix.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".continue/config.json" = {
        source = ./config.json;
      };
      ".continue/config.ts" = {
        source = ./config.ts;
      };
    };
  };
}
