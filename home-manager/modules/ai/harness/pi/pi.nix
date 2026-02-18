{
  lib,
  mylib,
  config,
  llm-agents,
  pkgs,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.pi;
  settingsPth = ".pi/agent/settings.json";
in
{
  options.modules.pi = {
    enable = lib.mkEnableOption "pi";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      llm-agents.pi

      (pkgs.writeShellScriptBin "pi-agent-setup" ''
        ${builtins.readFile ./setup.sh}
      '')

      (pkgs.writeShellScriptBin "p" ''
        set -euo pipefail

        ai-setup
        exec ai-sandbox pi "$@"
      '')
    ];

    modules.commonShell = {
      shellAliases = { };
    };

    home.file = {
      ".pi/agent/skills" = {
        source = ../../skills/_global;
      };
      ".pi/agent/extensions" = {
        source = ./extensions;
        recursive = true;
      };
      ".config/pi/repo-config-nix/settings.json" = {
        source = ./settings/repo-settings-tmpl.json;
      };
      "${settingsPth}.source" = {
        source = mylib.cleanJson pkgs ./settings/settings.jsonc;
        onChange = ''
          source="${config.home.homeDirectory}/${settingsPth}.source"
          target="${config.home.homeDirectory}/${settingsPth}"

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
  };
}
