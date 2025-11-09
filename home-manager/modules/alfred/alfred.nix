# TROUBLESHOOTING
# Sometimes an app can request no global shortcuts for a period.
# Bitwarden is common culprit, but you can find the app with:
# ioreg -l -w 0 | grep -i SecureInput
# ps -p <pid> -o pid,comm=
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
