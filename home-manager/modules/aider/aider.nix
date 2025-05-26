{
  lib,
  config,
  pkgs-latest,
  pkgs,
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
      (pkgs.writeShellScriptBin "aider-setup" ''
        ${builtins.readFile ./setup.sh}
      '')
    ];
    home.file = {
      ".config/aider/.aiderinclude" = {
        text = "";
      };
      ".config/aider/RULES.md" = {
        source = ./GLOBAL_AIDER.md;
      };
      ".aider.conf.yml" = {
        source = ./settings/aider.conf.yml;
      };
      ".aider.model.settings.yml" = {
        source = ./settings/aider-models.conf.yml;
      };
      # ".aider.model.metadata.json" = { source = ./aider-registry.json; };
    };

    modules.commonShell = {
      shellAliases = {
        aid = "aider-setup && aider --aiderignore .devdata/.aider/.aiderignore";
        aidw = "aider-setup && aider --aiderignore .devdata/.aider/.aiderignore --watch-files";
      };
    };
  };
}
