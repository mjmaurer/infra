{
  lib,
  config,
  pkgs,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.codex-cli;
in
{
  options.modules.codex-cli = {
    enable = lib.mkEnableOption "codex-cli";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs-latest.codex
    ];

    modules.commonShell = {
      shellAliases = {
        cx = "codex";
      };
    };
  };
}
