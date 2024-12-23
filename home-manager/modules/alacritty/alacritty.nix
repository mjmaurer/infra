{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.modules.alacritty;
  std = inputs.nix-std.lib;
in
{
  options.modules.alacritty = {
    enable = lib.mkEnableOption "alacritty";

    justConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "[NOOP currently] If true, only copy the config files without installing the package. For packages installed external to Nix.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Alacritty settings to merge with base configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = if cfg.justConfig then [ ] else [ pkgs.alacritty ];

    xdg.configFile = {
      "alacritty/alacritty.toml" = {
        text =
          let
            extraConfig = std.serde.toTOML cfg.settings;
          in
          ''
            # Base config
            ${builtins.readFile ./alacritty.toml}

            # Colors 
            # ---------------------------------- NOTE ---------------------------------- 
            # Color should be kept in sync with VSCode theme


            [colors.primary]
            background = '#${config.colorScheme.palette.base00}'
            foreground = '#${config.colorScheme.palette.base05}'

            # Normal colors
            [colors.normal]
            black   = '#${config.colorScheme.palette.base05}'
            red     = '#${config.colorScheme.palette.base08}'
            green   = '#${config.colorScheme.palette.base0B}'
            yellow  = '#${config.colorScheme.palette.base0A}'
            blue    = '#${config.colorScheme.palette.base0D}'
            magenta = '#${config.colorScheme.palette.base0E}'
            cyan    = '#${config.colorScheme.palette.base0C}'
            white   = '#${config.colorScheme.palette.base00}'
            # Note, for gruvbox, whtie was originally f2e5bc (darker)

            # Bright colors (same as normal colors)
            [colors.bright]
            black   = '#${config.colorScheme.palette.base05}'
            red     = '#${config.colorScheme.palette.base08}'
            green   = '#${config.colorScheme.palette.base0B}'
            yellow  = '#${config.colorScheme.palette.base0A}'
            blue    = '#${config.colorScheme.palette.base0D}'
            magenta = '#${config.colorScheme.palette.base0E}'
            cyan    = '#${config.colorScheme.palette.base0C}'
            white   = '#${config.colorScheme.palette.base00}'

            # Additional configuration from other modules
            ${extraConfig}
          '';
      };
    };
  };
}
