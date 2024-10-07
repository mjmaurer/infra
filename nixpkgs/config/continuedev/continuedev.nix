{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.configuration.continuedev;
in
{
  options.configuration.continuedev = {
    enable = lib.mkEnableOption "continuedev";
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
