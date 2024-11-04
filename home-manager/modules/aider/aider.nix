{ lib, config, pkgs, ... }:
let
  cfg = config.modules.aider;
in
{
  options.modules.aider = {
    enable = lib.mkEnableOption "aider";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.aider-chat ];
    home.file = {
      ".config/aider/.aiderignore" = {
        source = ./.aiderignore;
      };
      ".aider.conf.yml" = {
        source = ./aider.conf.yml;
      };
    };

    modules.commonShell = {
      shellAliases = {
        aid = "mkdir -p .aider && aider --4";
        aider = "mkdir -p .aider && aider --4";
        aids = "mkdir -p .aider && aider --sonnet";
        aidf = "mkdir -p .aider && aider --4";
        aidfo = "mkdir -p .aider && aider --4o";
      };
    };
  };
}
