{
  lib,
  mylib,
  config,
  pkgs,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.opencode;
  settingsPth = ".config/opencode/config.json";
  mcpConfig = import ../../mcp.json.nix;
  mcpServers = lib.mapAttrs (name: server: {
    type = "local";
    command = [ server.command ];
  }) mcpConfig.mcpServers;
in
{
  options.modules.opencode = {
    enable = lib.mkEnableOption "opencode";
  };

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs-latest.opencode;
      enableMcpIntegration = false;
      settings = {
        autoupdate = false;
        # mcp = mcpServers;
      };
    };

    home.file = {
      "${settingsPth}.source" = {
        source = mylib.cleanJson pkgs ./opencode_settings.jsonc;
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

    modules.commonShell = {
      shellAliases = {
        oc = "ai-setup && opencode";
      };
    };
  };
}
