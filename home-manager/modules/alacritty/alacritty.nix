{ nix-std, lib, config, pkgs, ... }:
let
  cfg = config.modules.alacritty;
  std = nix-std.lib;
in {
  options.modules.alacritty = {
    enable = lib.mkEnableOption "alacritty";

    justConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description =
        "[NOOP currently] If true, only copy the config files without installing the package. For packages installed external to Nix.";
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
        text = let
          # ---------------------------------- NOTE ---------------------------------- 
          # Color should be kept in sync with VSCode theme
          colorScheme = {
            black = "#${config.colorScheme.palette.base05}";
            red = "#${config.colorScheme.palette.base08}";
            green = "#${config.colorScheme.palette.base0B}";
            yellow = "#${config.colorScheme.palette.base0A}";
            blue = "#${config.colorScheme.palette.base0D}";
            magenta = "#${config.colorScheme.palette.base0E}";
            cyan = "#${config.colorScheme.palette.base0C}";
            # Note, for gruvbox, whtie was originally f2e5bc (darker)
            white = "#${config.colorScheme.palette.base00}";
          };
        in ''
          # Base config
          ${std.serde.toTOML {
            env.TERM = "alacritty";
            terminal = {
              shell = {
                program = "zsh";
                args = [ "-c" "tmuxp load term || echo 'Tmuxp Closed'" ];
              };
            };
            scrolling.history = 15000;
            window = {
              option_as_alt = "Both";
              opacity = 0.9;
              padding = {
                x = 10;
                y = 10;
              };
            };
            font = {
              size = 18;
              normal.family = "MesloLGS NF";
              bold.family = "MesloLGS NF";
              italic.family = "MesloLGS NF";
              offset = {
                x = 0;
                y = 0;
              };
              glyph_offset = {
                x = 0;
                y = 0;
              };
            };
          }}

          [keyboard]
          bindings = [
            { key = "PageUp", action = "ScrollHalfPageUp" },
            { key = "PageDown", action = "ScrollHalfPageDown" },
          ]

          # Colors 
          ${std.serde.toTOML {
            colors = {
              primary = {
                background = colorScheme.white;
                foreground = colorScheme.black;
              };
              normal = colorScheme;
              bright = colorScheme;
            };
          }}

          # Additional configuration from other modules
          ${std.serde.toTOML cfg.settings}
        '';
      };
    };
  };
}
