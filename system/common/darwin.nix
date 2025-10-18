{
  config,
  pkgs,
  derivationName,
  username,
  lib,
  ...
}:
let
  screenshotDir = "${config.users.users.${username}.home}/Documents/screenshots";
  cfg = config.modules.darwin;
in
{

  options.modules.darwin = {
    enable = lib.mkEnableOption "darwin";
  };

  imports = [
    ../modules/nix.nix
    ../modules/basic.nix
    ../modules/users.nix
    ../modules/networking.nix
    ../modules/samba/smb-client-darwin.nix

    ../modules/sops

    ../modules/kanata/kanata.nix
    ../modules/crypt.nix # Yubikey stuff

    ../modules/homebrew/homebrew.nix
    ../modules/aerospace/aerospace.nix
    # ../modules/intellibar
  ];

  config = {

    # Never change this here. Only in flake.nix
    system.stateVersion = lib.mkDefault 5;

    system.primaryUser = username;

    environment = {
      systemPath = [ "/opt/homebrew/bin" ];
      # To make this consistent with nixos
      # Symlinks to `/run/current-system/sw`
      pathsToLink = [ "/Applications" ];
      # Is this necessary?
      # systemPackages = [
      #   pkgs.coreutils
      # ];
    };

    modules.darwin.enable = lib.mkDefault true;
    modules.homebrew.enable = lib.mkDefault true;

    # Add ability to used TouchID for sudo authentication
    security.pam.services.sudo_local.touchIdAuth = true;

    system.defaults = lib.mkIf cfg.enable {
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        QuitMenuItem = true; # Enable quit in Finder app menu bar
        ShowPathbar = true;
        ShowStatusBar = true;

        _FXShowPosixPathInTitle = true;
        # When performing a search, search the current folder by default
        FXDefaultSearchScope = "SCcf";
      };
      dock = {
        autohide = true;
        show-recents = false;
      };
      screencapture = {
        location = screenshotDir;
        type = "png";
      };
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };
      NSGlobalDomain = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
        # Setting this too high will affect kanata (any_key + hold_key) will repeat any_key
        InitialKeyRepeat = 18;
        # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)
        KeyRepeat = 3;

        # "com.apple.swipescrolldirection" = false; # enable natural scrolling(default to true)
        "com.apple.sound.beep.feedback" = 0; # disable beep sound when pressing volume up/down key

        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };
      # Any settings here you could otherwise see with: 'defaults read <setting_name>'
      CustomUserPreferences = {
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
          AppleShowAllFiles = true;
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.dock" = {
          no-bouncing = true;
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        # Prevent Photos from opening automatically when plugging in certain removable media
        "com.apple.ImageCapture".disableHotPlug = true;
        "com.apple.symbolichotkeys" = {
          # Shorcut values: https://github.com/NUIKit/CGSInternal/blob/c4f6f559d624dc1cfc2bf24c8c19dbf653317fcf/CGSHotKeys.h
          # parameters = [«ASCII», «KEY_CODE», «MODIFIERS» ];
          # Ascii: https://www.ascii-code.com/
          # Key_codes: https://eastmanreference.com/complete-list-of-applescript-key-codes
          # Modifiers: https://gist.github.com/stephancasas/74c4621e2492fb875f0f42778d432973

          # Might be easier to set the shorcut in system prefs, then run
          # `defaults read com.apple.symbolichotkeys` to get the values.
          # Also helping for seeing if there are conflicts
          AppleSymbolicHotKeys = {
            # Disable 'Cmd + Space' for Spotlight Search
            "64" = {
              enabled = false;
            };
            # Disable 'Cmd + Alt + Space' for Finder search window
            "65" = {
              enabled = false;
            };
            # kCGSHotKeyScreenshot
            "28" = {
              enabled = true;
              value = {
                # cmd+3
                parameters = [
                  51
                  20
                  1048576
                ];
                type = "standard";
              };
            };
            # kCGSHotKeyScreenshotToClipboard
            "29" = {
              enabled = true;
              value = {
                # cmd+alt+3
                parameters = [
                  51
                  20
                  1572864
                ];
                type = "standard";
              };
            };
            # kCGSHotKeyScreenshotRegion
            "30" = {
              enabled = true;
              value = {
                # cmd+4
                parameters = [
                  52
                  21
                  1048576
                ];
                type = "standard";
              };
            };
            # kCGSHotKeyScreenshotRegionToClipboard
            "31" = {
              enabled = true;
              value = {
                # cmd+alt+4
                parameters = [
                  52
                  21
                  1572864
                ];
                type = "standard";
              };
            };
            # kCGSHotKeyDecreaseDisplayBrightness
            "53" = {
              enabled = true;
              value = {
                # cmd+9
                parameters = [
                  57
                  25
                  1048576
                ];
                type = "standard";
              };
            };
            # kCGSHotKeyIncreaseDisplayBrightness
            "54" = {
              enabled = true;
              value = {
                # cmd+0
                parameters = [
                  48
                  29
                  1048576
                ];
                type = "standard";
              };
            };
          };
        };
      };
    };

    # Allows for more tty prompts (for tmux)
    launchd.daemons.set-ptmx-max = {
      serviceConfig = {
        Label = "org.nix-darwin.set-ptmx-max";
        ProgramArguments = [
          "/usr/sbin/sysctl"
          "-w"
          "kern.tty.ptmx_max=1024"
        ];
        RunAtLoad = true;
        KeepAlive = false;
        StandardOutPath = "/var/log/set-ptmx-max.out.log";
        StandardErrorPath = "/var/log/set-ptmx-max.err.log";
      };
    };

    system.activationScripts."copyApps".text = ''
      #!/usr/bin/env bash
      mkdir -p ${screenshotDir}

      # From https://github.com/LnL7/nix-darwin/issues/214#issuecomment-2050027696

      # This used to work, but doesn't now
      # apps_source="${config.users.users.${username}.home}/Applications"

      apps_source="$HOME/Applications/Home Manager Apps"

      # Darwin system app source. Already copied by Darwin to "/Applications/Nix Apps"
      #apps_source="${config.system.build.applications}/Applications"

      app_target="$HOME/Applications/Nix Trampolines"

      mkdir -p "$app_target"

      echo "Copying apps from $apps_source to $app_target"
      ${pkgs.rsync}/bin/rsync --archive --checksum --chmod=-w --delete --copy-unsafe-links "$apps_source/" "$app_target"
    '';
  };
}
