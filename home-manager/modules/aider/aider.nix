{ lib, config, pkgs, ... }:
let cfg = config.modules.aider;
in {
  options.modules.aider = { enable = lib.mkEnableOption "aider"; };

  imports = [ ./tmux-aider-pick.nix ];

  config = lib.mkIf cfg.enable {
    # Include playwright for web requests
    home.packages = [ pkgs.aider-chat.withPlaywright ];
    home.file = {
      ".config/aider/.aiderignore" = { source = ./.aiderignore; };
      ".aider.conf.yml" = { source = ./aider.conf.yml; };
    };

    modules.commonShell = {
      shellAliases = {
        aid = "aider";
        aidw = "aider --watch-files";
      };
    };
  };
}
