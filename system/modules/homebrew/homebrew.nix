# This module is used to install Homebrew on Darwin.
# It unfortunately depends on a user, but also is a system module.
{
  nix-homebrew,
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.modules.homebrew;
in
{
  imports = [ nix-homebrew.darwinModules.nix-homebrew ];

  options.modules.homebrew = {
    enable = lib.mkEnableOption "homebrew";
    extraCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra casks to install.";
    };
    extraFormulas = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra brews / formula to install.";
    };
    brewPrefix = lib.mkOption {
      type = lib.types.str;
      default = "/opt/homebrew/bin";
      description = "Homebrew prefix.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "plist-write" ''
        # i.e. /Applications/superwhisper.app
        _APP_PATH=$1
        _DOMAIN=$(mdls -name kMDItemCFBundleIdentifier $_APP_PATH | awk -F'"' '{print $2}')
        defaults export $_DOMAIN - >> ~/infra/system/modules/homebrew/initial-plists/$_DOMAIN.xml
        echo "WARNING: Clean XML before committing"
      '')
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

    system.activationScripts."settingsImport".text = ''
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

      echo "Importing plists. If this requests permission, give Allacritty Full Disk Access"
      initialPlists=${pkgs.copyPathToStore ./initial-plists}
      for plist in "$initialPlists"/*.xml; do
        domain="$(basename "$plist" .xml)"
        defaults import "$domain" "$plist"

        # Try converting the plist to JSON using plutil.
        # desiredJson=$(plutil -convert json -o - "$plist" 2>/dev/null)

        # diffFound=false
        # # Iterate over each key defined in the plist.
        # for key in $(echo "$desiredJson" | jq -r 'keys[]'); do
        #   desiredVal=$(echo "$desiredJson" | jq -r --arg key "$key" '.[$key]')
        #   # Read the current value for the key. (If the key isn't set, mark it as a unique placeholder.)
        #   currentVal=$(defaults read "$domain" "$key" 2>/dev/null || echo "__UNSET__")
        #   if [ "$currentVal" != "$desiredVal" ]; then
        #     echo "Mismatch in '$domain': for key '$key', desired='$desiredVal' but current='$currentVal'"
        #     diffFound=true
        #     break
        #   fi
        # done

        # if [ "$diffFound" = true ]; then
        #   echo "Importing plist $plist"
        #   defaults import "$domain" "$plist"
        # else
        #   echo "Skipping import for $plist; all defined keys already match."
        # fi
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
      brewPrefix = cfg.brewPrefix;
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
        # "karabiner-elements"
        # "spotify"
        # "slack"
        # "zoom"
      ] ++ cfg.extraCasks;
      taps = [
        # "homebrew/cask-fonts"
        # "xorpse/formulae"
        # "cmacrae/formulae"
      ];
      brews = [ ] ++ cfg.extraFormulas; # e.g. "trippy"

      extraConfig = "";
    };
  };
}
