{
  lib,
  config,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.aichat;
in
{
  options.modules.aichat = {
    enable = lib.mkEnableOption "aichat";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs-latest.aichat ];

    # TODO: Remove these when aichat .23 is released on nixpkgs
    home.file = {
      "Library/Application Support/aichat/light.tmTheme" = {
        source = ./light.tmTheme;
      };
      "Library/Application Support/aichat/config.yaml" = {
        source = ./config.yaml;
      };
      ".local/bin/git-commit-ai.sh" = {
        source = ./git-commit-ai.sh;
        executable = true;
      };
    };

    xdg.configFile = {
      "aichat/config.yaml" = {
        source = ./config.yaml;
      };
      "aichat/light.tmTheme" = {
        source = ./light.tmTheme;
      };
      "aichat/roles" = {
        source = ./roles;
      };
    };

    modules.commonShell = {
      shellAliases = {
        "a" = "aichat --model gemini:gemini-2.5-flash-preview-04-17 -e";
        "ai" = "aichat --role quick";
        "gcai" = "git-commit-ai.sh";
      };
    };
  };
}
