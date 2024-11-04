{ lib, config, pkgs, ... }:
let
  cfg = config.modules.alacritty;
in
{
  options.modules.alacritty = {
    enable = lib.mkEnableOption "alacritty";

    justConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "[NOOP currently] If true, only copy the config files without installing the package. For packages installed external to Nix.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = if cfg.justConfig then [ ] else [ pkgs.alacritty ];

    home.file = {
      ".config/alacritty/alacritty.toml" = {
        source = ./alacritty.toml;
      };
    };
  };
}
