{ lib, config, colors, pkgs, ... }:
let
  cfg = config.modules.wayland;
  swayfont = "MesloLGS NF 14";
  modifier = "Mod1";
in {
  options.modules.wayland = { enable = lib.mkEnableOption "wayland"; };

  config = lib.mkIf cfg.enable {
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
    ];
    xdg.configFile."environment.d/envvars.conf".text = ''
      XDG_CURRENT_DESKTOP=sway
      XDG_SESSION_TYPE=wayland
      NIXOS_OZONE_WL=1
    '';
    programs = {

      rofi.enable = true;

      waybar = {
        enable = true;
        settings = [{
          layer = "bottom";
          position = "top";
          height = 40;
          modules-left = [ "sway/workspaces" "sway/mode" ];
          modules-center = [ "sway/window" ];
          modules-right = [ "clock" ];
          "sway/window" = {
            format = "{}";
            max-length = 50;
          };
          "sway/mode" = { format = "{}"; };
          clock = {
            format = "{:%H:%M}";
            tooltip-format = "{:%Y-%m-%d | %H:%M}";
            format-alt = "{:%Y-%m-%d}";
          };
        }];
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
    };
    services = {
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
      systemdIntegration = true;
      config = {
        fonts = {
          names = [ swayfont ];
          style = "Bold";
          size = 11.0;
        };
        gaps = {
          inner = 5;
          outer = 5;
        };
        input = {
          "*" = {
            xkb_layout = "us";
            xkb_options = "caps:swapescape";
          };
        };
        output = {
          "*" = { bg = "${../../artwork/lakelucerne.jpeg} center"; };
        };
        colors.focused = {
          background = colors.hex colors.dark;
          border = colors.hex colors.primary;
          text = colors.hex colors.light;
          childBorder = colors.hex colors.primary;
          indicator = colors.hex colors.accent;
        };
        window.border = 2;
        inherit modifier;
        keybindings = {
          # "${modifier}+d" = "exec rofi -show run | xargs swaymsg exec --";
          # "${modifier}+c" = "kill";
          # "${modifier}+Shift+r" = "reload";
          # "${modifier}+f" = "fullscreen";
          # "${modifier}+Return" = "exec alacritty";
          # "${modifier}+w" = "exec firefox";
          # "${modifier}+p" = "mode power";
          # "${modifier}+n" = "exec makoctl dismiss";
          # "${modifier}+Shift+n" = "exec makoctl dismiss -a";

          # "${modifier}+Ampersand" = "workspace number 1";
          # "${modifier}+BracketLeft" = "workspace number 2";
          # "${modifier}+BraceLeft" = "workspace number 3";
          # "${modifier}+BraceRight" = "workspace number 4";
          # "${modifier}+ParenLeft" = "workspace number 5";
          # "${modifier}+Equal" = "workspace number 6";
          # "${modifier}+Asterisk" = "workspace number 7";
          # "${modifier}+ParenRight" = "workspace number 8";
          # "${modifier}+Plus" = "workspace number 9";

          # "${modifier}+Shift+Ampersand" = "move container to workspace number 1, workspace number 1";
          # "${modifier}+Shift+BracketLeft" = "move container to workspace number 2, workspace number 2";
          # "${modifier}+Shift+BraceLeft" = "move container to workspace number 3, workspace number 3";
          # "${modifier}+Shift+BraceRight" = "move container to workspace number 4, workspace number 4";
          # "${modifier}+Shift+ParenLeft" = "move container to workspace number 5, workspace number 5";
          # "${modifier}+Shift+Equal" = "move container to workspace number 6, workspace number 6";
          # "${modifier}+Shift+Asterisk" = "move container to workspace number 7, workspace number 7";
          # "${modifier}+Shift+ParenRight" = "move container to workspace number 8, workspace number 8";
          # "${modifier}+Shift+Plus" = "move container to workspace number 9, workspace number 9";
          # "${modifier}+Shift+s" = "move scratchpad";
          # "${modifier}+s" = "scratchpad show";
        };
        workspaceAutoBackAndForth = true;
        modes = {
          power = {
            "q" = "exit";
            "r" = "exec systemctl reboot";
            "s" = "exec systemctl poweroff -i";
            "p" = "mode default";
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
