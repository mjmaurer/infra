{
  lib,
  config,
  pkgs,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.alfred;
  cfgHome = "${config.xdg.configHome}/alfred";
in
{
  options.modules.alfred = {
    enable = lib.mkEnableOption "alfred";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      "Library/Application\ Support/Alfred/Alfred.alfredpreferences/workflows/ai" = {
        source = ./workflows/ai;
        recursive = true;
      };
    };
  };
}
