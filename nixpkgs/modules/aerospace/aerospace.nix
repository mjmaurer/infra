{ lib, config, pkgs, ... }:
let
  cfg = config.configuration.aerospace;
in
{
  options.configuration.aerospace = {
    enable = lib.mkEnableOption "aerospace";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".config/aerospace/aerospace.toml" = {
        source = ./aerospace.toml;
      };
    };
  };
}
