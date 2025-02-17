{ config, pkgs, derivationName, username, lib, ... }: {
  # Never change this here.
  system.stateVersion = lib.mkDefault 5;

  imports = [
    ./_base.nix
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

  modules.smbClient.enable = true;

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

  # scriptName = "post-switch-add-applications.sh";
  # postSwitchAddScript = pkgs.writeShellScript scriptName ''
  #   #!/usr/bin/env bash

  #   # From https://github.com/NixOS/nix/issues/956#issuecomment-1367457122
  #   # Could instead try: https://github.com/LnL7/nix-darwin/blob/master/modules/system/applications.nix
  #   # Install all nix top level graphical apps
  #   # if [[ -d ~/.nix-profile/Applications ]]; then
  #   # 	(cd ~/.nix-profile/Applications;
  #   # 	for f in *.app ; do
  #   #     f_without_extension="''${f%%.app}"
  #   # 		mkdir -p ~/Applications/
  #   #     echo "Adding $f to ~/Applications/"
  #   # 		# Remove existing symlink if it exists
  #   # 		rm -f "$HOME/Applications/$f_without_extension"
  #   #     sleep 0.2
  #   # 		# Mac aliases don’t work on symlinks
  #   # 		f="$(readlink -f "$f")"
  #   # 		# Use Mac aliases because Spotlight / Alfred doesn’t like symlinks
  #   # 		/usr/bin/osascript -e "tell app \"Finder\" to make new alias file at POSIX file \"$HOME/Applications\" to POSIX file \"$f\""
  #   # 	done
  #   # 	)
  #   # fi
  # '';
  # postSwitchAddScriptRsync = pkgs.writeShellScript scriptName "";
  # `run` is used to obey Nix dry run 
  # run ${postSwitchAddScriptRsync} 

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
