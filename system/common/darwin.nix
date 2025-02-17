{ config, pkgs, derivationName, username, lib, ... }: {
  # Never change this here. Only in flake.nix
  system.stateVersion = lib.mkDefault 5;

  imports = [
    ../modules/nix.nix
    ../modules/basic.nix
    ../modules/users.nix
    ../modules/networking.nix
    ../modules/smb-client.nix
    # TODO ../modules/tailscale.nix

    ../modules/sops

    ../modules/kanata/kanata.nix
    ../modules/crypt.nix # Yubikey stuff

    ../modules/homebrew/homebrew.nix
    ../modules/aerospace/aerospace.nix
  ];

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

  services.nix-daemon.enable = true;

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  system.defaults = {
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
      location = "~/Documents/screenshots";
      type = "png";
    };
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      # normal minimum is 15 (225 ms), maximum is 120 (1800 ms)
      InitialKeyRepeat = 14;
      # normal minimum is 2 (30 ms), maximum is 120 (1800 ms)
      KeyRepeat = 3;

      # "com.apple.swipescrolldirection" = false; # enable natural scrolling(default to true)
      "com.apple.sound.beep.feedback" =
        0; # disable beep sound when pressing volume up/down key

      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };
    CustomUserPreferences = {
      NSGlobalDomain = {
        # Add a context menu item for showing the Web Inspector in web views
        WebKitDeveloperExtras = true;
      };
      "com.apple.desktopservices" = {
        # Avoid creating .DS_Store files on network or USB volumes
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.dock" = { no-bouncing = true; };
      "com.apple.AdLib" = { allowApplePersonalizedAdvertising = false; };
      # Prevent Photos from opening automatically when plugging in certain removable media
      "com.apple.ImageCapture".disableHotPlug = true;
    };
  };

  system.activationScripts.postUserActivation.text = ''
    #!/usr/bin/env bash
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
}
