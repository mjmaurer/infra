{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.duplicacy;
  repoIds = [ "nas" ];
  backupAndRestore = " -limit-rate 25000 -max-in-memory-entries 1024 -threads 4 -stats";
  backup = "backup ${backupAndRestore}";
  restore = "restore ${backupAndRestore}";
in
{
  options.modules.duplicacy = {
    # Just installs duplicacy and basic scripts
    enable = lib.mkEnableOption "duplicacy";
    # Adding any 'autoBackup' requires giving machine access to secrets.yaml in .sops.yaml.
    repos = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            options = {
              repoId = lib.mkOption {
                type = lib.types.enum repoIds;
              };
              localRepoPath = lib.mkOption {
                type = lib.types.str;
                description = "The local path to the repository.";
              };
              autoBackup = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Automatically run backups each Monday at 5 AM.";
              };
              autoInit = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Automatically initialize the repository if it does not exist.";
              };
              autoInitRestore = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Automatically restore the repository after init";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      duplicacy

      (pkgs.writeShellScriptBin "dup-log" ''
        journalctl --user -fu duplicacy.service
      '')
      (pkgs.writeShellScriptBin "dup-backup" ''
        # Run a backup immediately
        ${pkgs.duplicacy}/bin/duplicacy ${backup} 
      '')
      (pkgs.writeShellScriptBin "dup-activate" ''
        # Start the duplicacy timer to run backups
        systemctl --user start duplicacy.timer
      '')
      (pkgs.writeShellScriptBin "dup-status" ''
        # Show the status of the duplicacy timer
        systemctl --user list-timers duplicacy.timer
      '')
      # `nas` is the 'repository id' for the backup
      # The b2 bucket will be the 'storage', which can contain multiple repos (ID is also `nas` for legacy reasons).
      # Multiple repos in the same storage will still have file deduplication.
      (pkgs.writeShellScriptBin "dup-init" ''
        #!/bin/sh
        set -e

        if [ -z "$1" ] || [ -z "$2" ]; then
          echo "Usage: $0 REPO_ID REPO_DIR [STORAGE_URL]"
          echo "Error: REPO_ID and REPO_DIR are required."
          echo "Allowed REPO_IDs are: ${lib.concatStringsSep " " repoIds}"
          exit 1
        fi

        REPO_ID="$1"
        REPO_DIR="$2"

        if [ -z "$3" ] && [ -z "$BUCKET_NAME" ]; then
          echo "Error: BUCKET_NAME is not set and no STORAGE_URL was provided."
          exit 1
        fi

        STORAGE_URL="$${3:-"b2://$BUCKET_NAME"}"

        is_valid_repo_id=false
        ${lib.concatMapStringsSep "\n" (val: ''
          if [ "$REPO_ID" = "${lib.escapeShellArg val}" ]; then
            is_valid_repo_id=true
          fi
        '') repoIds}

        if [ "$is_valid_repo_id" = false ]; then
          echo "Error: Invalid REPO_ID '$REPO_ID'."
          echo "Allowed REPO_IDs are: ${lib.concatStringsSep ", " repoIds}"
          exit 1
        fi

        if [ ! -d "$REPO_DIR" ]; then
          echo "Error: Target directory '$REPO_DIR' for initialization does not exist or is not a directory."
          exit 1
        fi

        mkdir -p "$REPO_DIR"
        cd "$REPO_DIR" || { echo "Error: Failed to cd into '$REPO_DIR'"; exit 1; }

        echo "Initializing Duplicacy repository '$REPO_ID' in '$PWD'..."
        echo "Storage URL: '$STORAGE_URL'"

        # Warn if DUPLICACY_PASSWORD is not set, as 'duplicacy init' might need it.
        if [ -z "$DUPLICACY_PASSWORD" ]; then
            echo "Warning: DUPLICACY_PASSWORD is not set in the environment."
            echo "Duplicacy may prompt for it, or you can set it (e.g., via sops)."
        fi

        ${pkgs.duplicacy}/bin/duplicacy init -encrypt -zstd "$REPO_ID" "$STORAGE_URL"
        echo "Repository '$REPO_ID' initialized in '$PWD'."
        echo "You may want to run an initial backup using a command like: dup-backup-init"
      '')
      (pkgs.writeShellScriptBin "dup-backup-init" ''
        #!/bin/sh
        set -e
        if [ ! -d ".duplicacy" ]; then
          echo "Error: .duplicacy folder not found in current directory. Please initialize the repository first."
          exit 1
        fi
        ${pkgs.duplicacy}/bin/duplicacy ${backup} -t initial
      '')
    ];

    # modules.nix = {
    #   unfreePackages = [ "duplicacy" ];
    # };

    # https://forum.duplicacy.com/t/duplicacy-quick-start-cli/1101
    # https://forum.duplicacy.com/t/encryption-of-the-storage/1085
    systemd.services.duplicacy = {
      Unit.Description = "Duplicacy backup service";
      Service = {
        Restart = "no";
        WorkingDirectory = config.home.homeDirectory;
        ExecStart = pkgs.writeShellScript "run-duplicacy" ''
          #!/bin/zsh
          ${pkgs.duplicacy}/bin/duplicacy ${backup}
        '';
        EnvironmentFile = config.sops.templates.duplicacyConf.path;
      };
    };

    systemd.timers.duplicacy = {
      Unit.Description = "Timer for Duplicacy backup service";
      Timer = {
        Unit = "duplicacy.service";
        OnCalendar = "Mon *-*-* 05:00:00 America/New_York";
        Persistent = true; # Catch up on missed runs
      };
      Install.WantedBy = [ "timers.target" ];
    };

    sops = {
      secrets = {
        duplicacyB2Id = {
          sopsFile = ./secrets.yaml;
        };
        duplicacyB2Key = {
          sopsFile = ./secrets.yaml;
        };
        duplicacyB2Bucket = {
          sopsFile = ./secrets.yaml;
        };
        duplicacyPassword = {
          sopsFile = ./secrets.yaml;
        };
      };
      templates = {
        "duplicacyConf" = {
          # Owner / Group: Read
          # Other: No access
          mode = "0440";
          group = "TODO";
          content = ''
            DUPLICACY_B2_ID=${config.sops.placeholder.duplicacyB2Id}
            DUPLICACY_B2_KEY=${config.sops.placeholder.duplicacyB2Key}
            DUPLICACY_PASSWORD=${config.sops.placeholder.duplicacyPassword}
            BUCKET_NAME=${config.sops.placeholder.duplicacyB2Bucket}
          '';
          restartUnits = [ "duplicacy.service" ];
        };
      };
    };
  };
}
