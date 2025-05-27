{
  lib,
  config,
  colors,
  pkgs,
  ...
}:
let
  cfg = config.modules.wayland;
  swayfont = "MesloLGS NF 14";
  Super = "Mod4";
  Alt = "Mod1";
in
{
  options.modules.wayland = {
    enable = lib.mkEnableOption "wayland";
  };

  config = lib.mkIf cfg.enable {
    # Can find more packages / features here:
    # https://github.com/Misterio77/nix-config/tree/main/home/gabriel/features/desktop/common/wayland-wm
    # Might also want to split some of these out into separate modules for headless / headless-minimal
    home.packages = with pkgs; [
      xwayland # X11 compatibility layer for Wayland
      swaylock-effects # Screen locker for Sway with additional effects
      wl-clipboard # Command-line clipboard utilities for Wayland
      rofi # Application launcher and window switcher
      waybar # Highly customizable Wayland bar
      libnotify # Library for desktop notifications
      slurp # Select a region in Wayland compositors
      grim # wayland screenshot application that works
      imv # wayland image viewer that works
      pdfpc # pdf presentation viewer run with -s -S
      # (e.g., Nautilus, Thunar)
    ];

    xdg = {
      configFile."environment.d/envvars.conf".text = ''
        XDG_CURRENT_DESKTOP=sway
        XDG_SESSION_TYPE=wayland
        NIXOS_OZONE_WL=1 # For Electron apps (VSCode, Discord, etc.) using Ozone/Wayland
        MOZ_ENABLE_WAYLAND = "1"; # For Firefox
        QT_QPA_PLATFORM = "wayland;xcb"; # For Qt5/Qt6 apps, fallback to xcb
        SDL_VIDEODRIVER = "wayland";
        # GDK_BACKEND = "wayland"; # Usually handled by sway.wrapperFeatures.gtk or app defaults
      '';
      mime.enable = true;
    };

    programs = {

      rofi.enable = true;

      waybar = {
        enable = true;
        settings = [
          {
            layer = "bottom";
            position = "top";
            height = 40;
            modules-left = [
              "sway/workspaces"
              "sway/mode"
            ];
            modules-center = [ "sway/window" ];
            modules-right = [ "clock" ];
            "sway/window" = {
              format = "{}";
              max-length = 50;
            };
            "sway/mode" = {
              format = "{}";
            };
            clock = {
              format = "{:%H:%M}";
              tooltip-format = "{:%Y-%m-%d | %H:%M}";
              format-alt = "{:%Y-%m-%d}";
            };
          }
        ];
        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: 'Source Code Pro', 'Font Awesome 5';
            font-size: 20px;
            min-height: 0;
          }
          window#waybar {
            background: ${colors.css colors.dark 0.5};
            border-bottom: 3px solid ${colors.css colors.primary 0.5};
            color: ${colors.hex colors.light};
          }
          window#waybar.hidden {
            opacity: 0.0;
          }
          #workspaces button {
            padding: 0 5px;
            background: transparent;
            color: ${colors.hex colors.light};
            border-bottom: 3px solid transparent;
          }
          #workspaces button.focused {
            background: ${colors.hex colors.primary};
            border-bottom: 3px solid ${colors.hex colors.dark};
          }
          #workspaces button.urgent {
            background-color: ${colors.hex colors.red};
          }
          #clock, #cpu, #memory, #temperature, #backlight, #network, #pulseaudio, #mode, #idle_inhibitor {
            padding: 0 10px;
            margin: 0 5px;
          }
        '';
        systemd = {
          enable = true;
          target = "sway-session.target";
        };
      };

      swaylock.settings = {
        screenshots = true;
        clock = true;
        indicator = true;
        show-failed-attempts = true;
        ignore-empty-password = true;
        grace = 2;
        effect-blur = "7x5";
        effect-vignette = "0.6:0.6";
        ring-color = colors.hex colors.accent;
        ring-ver-color = colors.hex colors.green;
        ring-wrong-color = colors.hex colors.red;
        key-hl-color = colors.hex colors.primary;
        line-color = "00000000";
        line-ver-color = "00000000";
        line-wrong-color = "00000000";
        inside-color = "00000000";
        inside-ver-color = "00000000";
        inside-wrong-color = "00000000";
        separator-color = "00000000";
        text-color = colors.hex colors.light;
      };
    };
    services = {

      # Notification daemon
      mako = {
        enable = true;
        anchor = "top-right";
        backgroundColor = colors.hex colors.dark;
        textColor = colors.hex colors.light;
        borderColor = colors.hex colors.primary;
        borderRadius = 5;
        borderSize = 2;
        font = "MesloLGS NF 14";
      };

      swayidle = {
        enable = true;
        timeouts = [
          # After 5 minutes of inactivity:
          # Lock the screen with swaylock (force lock even if there are inhibitors)
          {
            timeout = 300; # seconds
            command = "${pkgs.swaylock}/bin/swaylock -f";
          }
          # After 10 minutes of inactivity:
          # Turn off all displays using DPMS
          # When activity is detected, turn displays back on
          {
            timeout = 600; # seconds
            command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
            resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
          }
        ];
      };
    };
    wayland.windowManager.sway = {
      enable = true;
      systemd.enable = true;
      wrapperFeatures.gtk = true;
      checkConfig = true;
      config = {
        fonts = {
          names = [ swayfont ];
          style = "Bold";
          size = 11.0;
        };
        gaps = {
          inner = 0;
          outer = 0;
        };
        input = {
          "*" = {
            xkb_layout = "us";
            xkb_options = "caps:swapescape";
          };
        };
        output = {
          "*" = {
            bg = "${../../../artwork/ruinsoftheparthenon.jpeg} center";
          };
        };
        colors.focused = {
          background = colors.hex colors.dark;
          border = colors.hex colors.primary;
          text = colors.hex colors.light;
          childBorder = colors.hex colors.primary;
          indicator = colors.hex colors.accent;
        };
        window.border = 2;
        # Sway can only have one main modifier, so we have to manually set most bindings
        modifier = Super;
        keybindings =
          let
            hypmods = "Control+${Super}";
            sysmods = "Control+${Super}+${Alt}";
          in
          {
            "${sysmods}+x" = "kill";

            "${hypmods}+p" = "exec rofi -show run | xargs swaymsg exec --";
            "${hypmods}+c" = "reload";
            "${hypmods}+f" = "fullscreen";
            "${hypmods}+Return" = "mode power";

            # Flattening workspace
            "${hypmods}+Shift+f" = "layout stacking";

            "${hypmods}+Shift+h" = "move left";
            "${hypmods}+Shift+j" = "move down";
            "${hypmods}+Shift+k" = "move up";
            "${hypmods}+Shift+l" = "move right";

            # "${modifier}+n" = "exec makoctl dismiss";
            # "${modifier}+Shift+n" = "exec makoctl dismiss -a";

            # Workspace navigation
            "${hypmods}+w" = "workspace number 1:web";
            "${hypmods}+t" = "workspace number 2:terminal";
            "${hypmods}+e" = "workspace number 3:code";
            "${hypmods}+g" = "workspace number 4:files";
            "${hypmods}+a" = "workspace number 5:llm";
            "${hypmods}+r" = "workspace number 6:notes";
            "${hypmods}+m" = "workspace number 7:music";

            # Move container to workspace and follow
            "${hypmods}+Shift+w" = "move container to workspace number 1:web; workspace number 1:web";
            "${hypmods}+Shift+t" = "move container to workspace number 2:terminal; workspace number 2:terminal";
            "${hypmods}+Shift+e" = "move container to workspace number 3:code; workspace number 3:code";
            "${hypmods}+Shift+g" = "move container to workspace number 4:files; workspace number 4:files";
            "${hypmods}+Shift+a" = "move container to workspace number 5:llm; workspace number 5:llm";
            "${hypmods}+Shift+r" = "move container to workspace number 6:notes; workspace number 6:notes";
            "${hypmods}+Shift+m" = "move container to workspace number 7:music; workspace number 7:music";

            "${hypmods}+s" = "scratchpad show";
            "${hypmods}+Shift+s" = "move scratchpad";
          };
        workspaceAutoBackAndForth = true;

        # For 'class', (?i) makes the match case-insensitive.
        assigns = {
          "1:web" = [
            { class = "(?i)firefox"; }
            { class = "(?i)brave-browser"; }
            { class = "(?i)chromium"; }
          ];
          "2:terminal" = [
            { class = "(?i)alacritty"; }
          ];
          "3:code" = [
            { class = "(?i)code"; }
          ];
          "4:files" = [
            { class = "(?i)imv"; }
            { class = "(?i)pdfpc"; }
          ];
          "5:llm" = [
            { class = "(?i)chat-gpt"; } 
          ];
          "6:notes" = [
            { class = "(?i)obsidian"; }
          ];
          "7:music" = [
            { class = "(?i)spotify"; }
          ];
        };

        modes = {
          power = {
            "q" = "exit";
            "r" = "exec systemctl reboot";
            "s" = "exec systemctl poweroff -i";
            "Escape" = "mode default";
            "Return" = "mode default";
          };
        };
        bars = [ ];
        startup = [ ];
      };
    };
  };
}
