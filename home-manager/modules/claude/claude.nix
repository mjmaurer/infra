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
      # claude-package
      pkgs-latest.claude-code

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
