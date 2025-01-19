# This module is used to install Homebrew on Darwin.
# It unfortunately depends on a user, but also is a system module.

{ inputs, pkgs, username, ... }:
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;

    # User owning the Homebrew prefix
    user = username;

    # Automatically migrate existing Homebrew installations
    autoMigrate = true;
  };

  system.activationScripts.postUserActivation.text = ''
    #!${pkgs.zsh}/bin/zsh
    DOCKER_CONFIG="$HOME/Library/Group Containers/group.com.docker/settings-store.json"
    DOCKER_SETTINGS_TEMPLATE="${pkgs.copyPathToStore ./docker-settings.json}"

    if [ ! -f "$DOCKER_CONFIG" ]; then
      mkdir -p "$(dirname "$DOCKER_CONFIG")"
      cp "$DOCKER_SETTINGS_TEMPLATE" "$DOCKER_CONFIG"
      echo "Created initial Docker settings at $DOCKER_CONFIG"
    else
      if ! diff -w "$DOCKER_CONFIG" "$DOCKER_SETTINGS_TEMPLATE"; then
        echo "Warning: Docker settings.json differs from Nix template"
        echo "Template location: $DOCKER_SETTINGS_TEMPLATE"
        echo "Current config: $DOCKER_CONFIG"
      fi
    fi

    initialPlists=${pkgs.copyPathToStore ./initial-plists}
    for plist in "$initialPlists"/*.xml; do
      echo "Importing plist $plist"
      defaults import "$(basename "$plist" .xml)" "$plist"
    done
  '';


  # Could use something like this to set custom shortcuts
  # system.defaults = {
  #   CustomUserPreferences = {
  #     "com.lwouis.alt-tab-macos".holdShortcut = "\\U2318";
  #   };
  # };

  # NOTE: I had to run `brew cleanup` to fix a symlink issue with completions for some reason.

  # Docs: https://daiderd.com/nix-darwin/manual/index.html#opt-homebrew.enable
  homebrew = {
    brewPrefix = "/opt/homebrew/bin";
    enable = true;
    caskArgs.no_quarantine = true;
    global = {
      brewfile = true;
      # Disables auto-update for various brew commands 
      autoUpdate = false;
    };
    # With this setup, you must run `brew update` to get the latest versions of packages
    # and then rebuild darwin to upgrade.
    onActivation = {
      upgrade = true;
      autoUpdate = false;
      # cleanup = true;
    };
    casks = [
      {
        name = "alfred";
        # Could be issues? https://github.com/LnL7/nix-darwin/issues/1212
        # restart_service = true;
      }
      "docker"
      "ente-auth"
      # Remove after ente supports auto-lock
      "quitter"
      "homerow"
      "alt-tab"
      "bitwarden"
      "superwhisper"
      # "spotify"
      # "slack"
      # "zoom"
    ];
    taps = [
      # "homebrew/cask-fonts"
      # "xorpse/formulae"
      # "cmacrae/formulae"
    ];
    brews = [ ]; # e.g. "trippy"

    extraConfig = ''
    '';
  };
}
