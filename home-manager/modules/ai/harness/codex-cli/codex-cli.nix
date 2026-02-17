{
  lib,
  config,
  nix-std,
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
      (pkgs.writeShellScriptBin "whistle" ''
        ${pkgs.afplay or "/usr/bin/afplay"} ${../../sounds/short_whistle.mp3}
      '')
      (pkgs.writeShellScriptBin "codex-agent-setup" ''
        ${builtins.readFile ./setup.sh}
      '')
    ];
    home.file = {
      ".codex/repo-config-nix/config-tmpl.toml" = {
        source = ./config/repo-config-tmpl.toml;
      };
      ".codex/config.toml.source" = {
        text =
          let
            baseConfig = builtins.readFile ./config/config.toml;
            mcpConfig = import ../../mcp.json.nix;
            mcpRenamed = {
              mcp_servers = mcpConfig.mcpServers;
              notify = [ "whistle" ];
            };
            mcpTomlText = nix-std.lib.serde.toTOML mcpRenamed;
          in
          baseConfig + "\n" + mcpTomlText;

        onChange = ''
          source="${config.home.homeDirectory}/.codex/config.toml.source"
          target="${config.home.homeDirectory}/.codex/config.toml"

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
    };

    modules.commonShell = {
      shellAliases = {
        cx = "ai-setup && codex";
      };
    };
  };
}
