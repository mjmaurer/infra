{
  lib,
  config,
  pkgs,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.claude;

  # claude-package = import ./deriv {
  #   inherit lib;
  #   pkgs = pkgs;
  # };
in
{
  options.modules.claude = {
    enable = lib.mkEnableOption "claude";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # Uses claude-code flake via overlay configured in system.nix
      pkgs-latest.claude-code
      pkgs-latest.mcp-nixos

      (pkgs.writeShellScriptBin "claude-agent-setup" ''
        ${builtins.readFile ./setup.sh}
      '')

      (pkgs.writeShellScriptBin "cl" ''
        set -euo pipefail

        ai-setup
        exec claude "$@"
      '')
    ];
    home.file = {
      # Claude Code will make updates to this, so we need to make it writable
      # https://github.com/anthropics/claude-code/issues/4808
      ".claude/settings.json.source" = {
        text = lib.generators.toJSON { } (import ./settings/user-settings.nix);
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
      ".claude/local-settings-tmpl.json" = {
        source = ./settings/local-settings-tmpl.jsonc;
      };
      ".claude/commands" = {
        source = ./commands;
      };
    };

    modules.commonShell = {
      shellAliases =
        let
          # See mcp.json.nix for mcp.json
          baseClaude = "ai-setup && claude"; # --mcp-config ~/.config/ai/mcp.json";
          # mcp.json is symlinked in each project so
          # we can default to `enableAllProjectMcpServers = false;`
        in
        {
          clp = "cl -p";
        };
    };
  };
}
