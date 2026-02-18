{
  lib,
  mylib,
  config,
  pkgs,
  pkgs-latest,
  llm-agents,
  ...
}:
let
  cfg = config.modules.claude;
  # Build a cleaned, valid JSON file in the Nix store.

  # claude-package = import ./deriv {
  #   inherit lib;
  #   pkgs = pkgs;
  # };

  trace-pkgs = import ./trace.nix { inherit lib pkgs-latest; };
  inherit (trace-pkgs) claude-trace claude-trace-viewer;
in
{
  options.modules.claude = {
    enable = lib.mkEnableOption "claude";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # Uses claude-code flake via overlay configured in system.nix
      llm-agents.claude-code

      claude-trace
      claude-trace-viewer

      (pkgs.writeShellScriptBin "claude-agent-setup" ''
        ${builtins.readFile ./setup.sh}
      '')

      (pkgs.writeShellScriptBin "cl" ''
        set -euo pipefail

        ai-setup
        unset ANTHROPIC_API_KEY
        exec ai-sandbox claude "$@"
      '')
    ];
    modules.commonShell = {
      shellAliases = {
        clp = "cl -p";
      };
    };
    home.file = {
      # --------------------------- User-wide settings ---------------------------
      # Claude Code will make updates to this, so we need to make it writable
      # https://github.com/anthropics/claude-code/issues/4808
      ".claude/settings.json.source" = {
        source = mylib.cleanJson pkgs ./settings/user-settings.jsonc;
        onChange = ''
          source="${config.home.homeDirectory}/.claude/settings.json.source"
          target="${config.home.homeDirectory}/.claude/settings.json"

          # Check if a regular file exists and if it's different from the source
          if [ -f "$target" ] && [ ! -L "$target" ] && ! cmp -s "$source" "$target"; then
            # Create a timestamped backup only if files are different
            backup_date=$(date +%Y-%m-%d_%H-%M-%S)
            echo "Contents of $target differ. Backing up to $target.backup.$backup_date"
            mv "$target" "$target.backup.$backup_date"
          fi

          # Overwrites the content with the actual source
          cp -f $source $target
          chmod +w $target
        '';
      };
      # --------------------------- Repo-wide settings tmpl ---------------------------
      ".claude/repo-config-nix/settings-tmpl.json" = {
        source = ./settings/repo-settings-tmpl.jsonc;
      };
      ".claude/skills" = {
        source = ../../skills/_global;
      };
    };
  };
}
