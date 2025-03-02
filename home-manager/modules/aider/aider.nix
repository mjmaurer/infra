{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modules.aider;
  aider-package = import ./aider-deriv.nix { inherit pkgs lib; };
in
{
  options.modules.aider = {
    enable = lib.mkEnableOption "aider";
  };

  imports = [ ./tmux-aider-pick.nix ];

  config = lib.mkIf cfg.enable {
    # Include playwright for web requests
    home.packages = [ aider-package.withPlaywright ];
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
