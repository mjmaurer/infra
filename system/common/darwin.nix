{ config, pkgs, derivationName, username, lib, ... }:
{
  # Never change this here.
  system.stateVersion = lib.mkDefault 5;

  imports = [
    ./_base.nix
    ../modules/homebrew/homebrew.nix
  ];

  environment = {
    systemPath = [
      "/opt/homebrew/bin"
    ];
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
      "com.apple.sound.beep.feedback" = 0; # disable beep sound when pressing volume up/down key

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
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      # Prevent Photos from opening automatically when plugging in certain removable media
      "com.apple.ImageCapture".disableHotPlug = true;
    };
  };
}
