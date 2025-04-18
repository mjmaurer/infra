{
  lib,
  config,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.aider;
in
# NOTE: An overlay is defined in `lib/system.nix` to add google deps
# aider-package = import ./aider-deriv.nix {
#   inherit lib;
#   pkgs = pkgs-latest;
# };
{
  options.modules.aider = {
    enable = lib.mkEnableOption "aider";
  };

  imports = [ ./tmux-aider-pick.nix ];

  config = lib.mkIf cfg.enable {
    # Include playwright for web requests
    home.packages = [
      (pkgs-latest.aider-chat.withOptional {
        withPlaywright = true;
      })
    ];
    home.file = {
      ".config/aider/.aiderignore" = {
        source = ./.aiderignore;
      };
      ".aider.conf.yml" = {
        source = ./aider.conf.yml;
      };
      ".aider.model.settings.yml" = {
        source = ./aider-models.conf.yml;
      };
      # ".aider.model.metadata.json" = { source = ./aider-registry.json; };
    };

    modules.commonShell = {
      shellAliases = {
        aid = "aider";
        aidw = "aider --watch-files";
      };
    };
  };
}
