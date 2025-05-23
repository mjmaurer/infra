{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modules.claude;

  claude-package = import ./deriv {
    inherit lib;
    pkgs = pkgs;
  };
in
{
  options.modules.claude = {
    enable = lib.mkEnableOption "claude";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      claude-package

      (pkgs.writeShellScriptBin "claude-setup" ''
        ${builtins.readFile ./setup.sh}
      '')
    ];
    home.file = {
      ".claude/CLAUDE.md" = {
        source = ./GLOBAL_CLAUDE.md;
      };
      ".claude/LOCAL_CLAUDE.md" = {
        source = ./LOCAL_CLAUDE.md;
      };
    };

    modules.commonShell = {
      shellAliases = {
        cl = "claude-setup && claude";
        clp = "claude-setup && claude -p";
      };
    };
  };
}
