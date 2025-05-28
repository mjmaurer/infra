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
      ".claude/LOCAL_CLAUDE_TMPL.md" = {
        source = ./LOCAL_CLAUDE_TMPL.md;
      };
      ".claude/settings.json" = {
        text = lib.generators.toJSON { } (import ./settings/global-settings.nix);
      };
      ".claude/local-settings-tmpl.json" = {
        text = lib.generators.toJSON { } (import ./settings/local-settings-tmpl.nix);
      };
      ".claude/commands" = {
        source = ./commands;
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
