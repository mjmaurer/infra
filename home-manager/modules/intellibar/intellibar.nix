{
  osConfig ? null,
  lib,
  config,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.intellibar;
in
# NOTE: An overlay is defined in `lib/system.nix` to add google deps
# aider-package = import ./aider-deriv.nix {
#   inherit lib;
#   pkgs = pkgs-latest;
# };
{
  options.modules.intellibar = {
    enable = lib.mkEnableOption "intellibar";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
