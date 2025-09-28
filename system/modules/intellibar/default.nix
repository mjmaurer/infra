{
  config,
  pkgs,
  username,
  lib,
  ...
}:
let
  cfg = config.modules.intellibar;
in
{
  options.modules.intellibar = {
    enable = lib.mkEnableOption "intellibar";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.imports = [
      (
        {
          config,
          osConfig,
          pkgs-latest,
          ...
        }:
        {
          home.file = {
            ".intellibar/instructions/" = {
              source = ./instructions;
              recursive = true;
            };
            ".intellibar/models/pro-25-preview.yaml" = {
              source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."pro-25-preview.yaml".path;
            };
            ".intellibar/models/flash-25-preview.yaml" = {
              source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."flash-25-preview.yaml".path;
            };
            ".intellibar/models/flash-thinking-25-preview-openrouter.yaml" = {
              source =
                config.lib.file.mkOutOfStoreSymlink
                  osConfig.sops.templates."flash-thinking-25-preview-openrouter.yaml".path;
            };
            ".intellibar/models/flash-25-preview-openrouter.yaml" = {
              source =
                config.lib.file.mkOutOfStoreSymlink
                  osConfig.sops.templates."flash-25-preview-openrouter.yaml".path;
            };
            ".intellibar/models/pro-25-preview-openrouter.yaml" = {
              source =
                config.lib.file.mkOutOfStoreSymlink
                  osConfig.sops.templates."pro-25-preview-openrouter.yaml".path;
            };
            ".intellibar/models/o3.yaml" = {
              source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."o3.yaml".path;
            };
            ".intellibar/models/o4-mini.yaml" = {
              source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."o4-mini.yaml".path;
            };
          };
        }
      )
    ];
  };
}

