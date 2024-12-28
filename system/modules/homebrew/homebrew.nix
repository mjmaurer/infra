# This module is used to install Homebrew on Darwin.
# It unfortunately depends on a user, but also is a system module.

{ inputs, homebrewUser, ... }:
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
    user = homebrewUser;

    # Automatically migrate existing Homebrew installations
    autoMigrate = true;
  };

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
      {
        # Might need separate plugins (docker-compose, docker-buildx, etc.)
        name = "docker";
        # restart_service = true;
      }
      # Remove after ente supports auto-lock
      "quitter"
      # "spotify"
      # "slack"
      # "zoom"
    ];
    taps = [
      "homebrew/core"
      "homebrew/cask"
      # "homebrew/cask-fonts"
      # "xorpse/formulae"
      # "cmacrae/formulae"
    ];
    brews = [ ]; # e.g. "trippy"

    extraConfig = ''
    '';
  };
}
