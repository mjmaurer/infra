{ config, pkgs, lib, ... }:
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

  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      _FXShowPosixPathInTitle = true;
    };
    dock = {
      autohide = true;
      show-recents = false;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
    };
    screencapture.location = "~/Documents/screenshots";
    screensaver.askForPassword = true;
    # networking = {
    #   hostName = "aspen";
    #   localHostName = "aspen";
    # };
  };
}