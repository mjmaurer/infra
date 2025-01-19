{ lib, config, pkgs, ... }:
let cfg = config.modules.aerospace;
in {
  options.modules.aerospace = {
    enable = lib.mkEnableOption "aerospace";

    justConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "[NOOP currently] If true, only copy the config files without installing the package. For packages installed external to Nix.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".config/aerospace/aerospace.toml" = { source = ./aerospace.toml; };
      ".local/bin/tmux-match-focus-vscode.sh" = {
        source = ./tmux-match-focus-vscode.sh;
        executable = true;
      };
    };

    modules.commonShell = { shellAliases = { "al" = "aerospace list-apps"; }; };
  };
}
