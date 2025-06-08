{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.duplicacy;
  repoIds = [ "nas" ]; # Still used for options.modules.duplicacy.repos.*.repoId type
  backupAndRestore = " -limit-rate 25000 -max-in-memory-entries 1024 -threads 4 -stats";
  backup = "backup ${backupAndRestore}";
  restore = "restore ${backupAndRestore}";

  escapeStringForShellDoubleQuotes = str: lib.replaceChars ["\\" "\"" "$" "`"] ["\\\\" "\\\"" "\\$" "\\\`"] str;

  repoKeysList = lib.attrNames cfg.repos;
  allowedRepoKeysStr = lib.concatStringsSep ", " repoKeysList;
  usageHint =
    if repoKeysList == [] then
      "No repositories configured in system.modules.duplicacy.repos."
    else
      "Allowed REPO_KEYs are: ${allowedRepoKeysStr}";
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
              storagePath = lib.mkOption {
                type = lib.types.str;
                description = "The local path to the storage.";
                default = "b2://$BUCKET_NAME";
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
      (pkgs.writeShellScriptBin "dup-activate" ''
        # Start the duplicacy timer to run backups
        systemctl --user start duplicacy.timer
      '')
      (pkgs.writeShellScriptBin "dup-status" ''
        # Show the status of the duplicacy timer
        systemctl --user list-timers duplicacy.timer
      '')
      (pkgs.writeShellScriptBin "dup-backup" ''
        #!/bin/sh
        set -e

        if [ -z "$1" ]; then
          echo "Usage: $0 REPO_KEY [duplicacy_options]"
          echo "Error: REPO_KEY is required."
          echo "${escapeStringForShellDoubleQuotes usageHint}"
          exit 1
        fi

        REPO_KEY="$1"
        shift # Allow passing additional arguments to duplicacy
        LOCAL_REPO_PATH=""

        case "$REPO_KEY" in
        ${lib.concatMapStringsSep "\n" (key: ''
          "${key}")
            LOCAL_REPO_PATH="${escapeStringForShellDoubleQuotes cfg.repos."${key}".localRepoPath}"
            ;;
        '') repoKeysList}
          *)
            echo "Error: Invalid REPO_KEY '$REPO_KEY'."
            echo "${escapeStringForShellDoubleQuotes usageHint}"
            exit 1
            ;;
        esac

        if [ ! -d "$LOCAL_REPO_PATH" ]; then
          echo "Error: Target directory '$LOCAL_REPO_PATH' for backup (derived from REPO_KEY '$REPO_KEY') does not exist or is not a directory. Run dup-init first."
          exit 1
        fi

        cd "$LOCAL_REPO_PATH" || { echo "Error: Failed to cd into '$LOCAL_REPO_PATH'"; exit 1; }
        
        if [ ! -d ".duplicacy" ]; then
          echo "Error: .duplicacy folder not found in '$LOCAL_REPO_PATH'. Please initialize the repository first (e.g. using dup-init '$REPO_KEY')."
          exit 1
        fi

        echo "Running backup for repository in '$PWD' (REPO_KEY: '$REPO_KEY')..."
        ${pkgs.duplicacy}/bin/duplicacy ${backup} "$@"
      '')
      (pkgs.writeShellScriptBin "dup-restore" ''
        #!/bin/sh
        set -e

        if [ -z "$1" ]; then
          echo "Usage: $0 REPO_KEY [duplicacy_options]"
          echo "Error: REPO_KEY is required."
          echo "${escapeStringForShellDoubleQuotes usageHint}"
          exit 1
        fi

        REPO_KEY="$1"
        shift # Allow passing additional arguments to duplicacy
        LOCAL_REPO_PATH=""

        case "$REPO_KEY" in
        ${lib.concatMapStringsSep "\n" (key: ''
          "${key}")
            LOCAL_REPO_PATH="${escapeStringForShellDoubleQuotes cfg.repos."${key}".localRepoPath}"
            ;;
        '') repoKeysList}
          *)
            echo "Error: Invalid REPO_KEY '$REPO_KEY'."
            echo "${escapeStringForShellDoubleQuotes usageHint}"
            exit 1
            ;;
        esac

        if [ ! -d "$LOCAL_REPO_PATH" ]; then
          echo "Error: Target directory '$LOCAL_REPO_PATH' for restore (derived from REPO_KEY '$REPO_KEY') does not exist or is not a directory."
          exit 1
        fi

        cd "$LOCAL_REPO_PATH" || { echo "Error: Failed to cd into '$LOCAL_REPO_PATH'"; exit 1; }
        
        if [ ! -d ".duplicacy" ]; then
          echo "Error: .duplicacy folder not found in '$LOCAL_REPO_PATH'. Please initialize the repository first (e.g. using dup-init '$REPO_KEY')."
          exit 1
        fi

        echo "Running restore for repository in '$PWD' (REPO_KEY: '$REPO_KEY')..."
        ${pkgs.duplicacy}/bin/duplicacy ${restore} "$@"
      '')
      # `nas` is the 'repository id' for the backup
      # The b2 bucket will be the 'storage', which can contain multiple repos (ID is also `nas` for legacy reasons).
      # Multiple repos in the same storage will still have file deduplication.
      (pkgs.writeShellScriptBin "dup-init" ''
        #!/bin/sh
        set -e

        if [ -z "$1" ]; then
          echo "Usage: $0 REPO_KEY [duplicacy_options]"
          echo "Error: REPO_KEY is required."
          echo "${escapeStringForShellDoubleQuotes usageHint}"
          exit 1
        fi

        REPO_KEY="$1"
        shift # Allow passing additional arguments to duplicacy
        REPO_ID_VAL=""
        LOCAL_REPO_PATH=""
        STORAGE_PATH_VAL=""

        case "$REPO_KEY" in
        ${lib.concatMapStringsSep "\n" (key: ''
          "${key}")
            REPO_ID_VAL="${escapeStringForShellDoubleQuotes cfg.repos."${key}".repoId}"
            LOCAL_REPO_PATH="${escapeStringForShellDoubleQuotes cfg.repos."${key}".localRepoPath}"
            STORAGE_PATH_VAL="${escapeStringForShellDoubleQuotes cfg.repos."${key}".storagePath}"
            ;;
        '') repoKeysList}
          *)
            echo "Error: Invalid REPO_KEY '$REPO_KEY'."
            echo "${escapeStringForShellDoubleQuotes usageHint}"
            exit 1
            ;;
        esac

        case "$STORAGE_PATH_VAL" in
          *\\$BUCKET_NAME*)
            if [ -z "$BUCKET_NAME" ]; then
              echo "Error: BUCKET_NAME is not set in the environment, but it is required by the storage path '$STORAGE_PATH_VAL'."
              exit 1
            fi
            ;;
        esac
        
        ACTUAL_STORAGE_URL=$(eval echo "$STORAGE_PATH_VAL")

        if [ ! -d "$LOCAL_REPO_PATH" ]; then
          echo "Info: Target directory '$LOCAL_REPO_PATH' for initialization (derived from REPO_KEY '$REPO_KEY') does not exist. Creating it."
          mkdir -p "$LOCAL_REPO_PATH" || { echo "Error: Failed to create directory '$LOCAL_REPO_PATH'"; exit 1; }
        fi
        
        cd "$LOCAL_REPO_PATH" || { echo "Error: Failed to cd into '$LOCAL_REPO_PATH'"; exit 1; }

        echo "Initializing Duplicacy repository '$REPO_ID_VAL' in '$PWD' (REPO_KEY: '$REPO_KEY')..."
        echo "Storage URL: '$ACTUAL_STORAGE_URL'"

        if [ -z "$DUPLICACY_PASSWORD" ]; then
            echo "Warning: DUPLICACY_PASSWORD is not set in the environment."
            echo "Duplicacy may prompt for it, or you can set it (e.g., via sops)."
        fi

        ${pkgs.duplicacy}/bin/duplicacy init -encrypt -zstd "$REPO_ID_VAL" "$ACTUAL_STORAGE_URL" "$@"
        echo "Repository '$REPO_ID_VAL' initialized in '$PWD'."
        echo "You may want to run an initial backup using a command like: dup-backup-init"
      '')
      (pkgs.writeShellScriptBin "dup-backup-init" ''
        #!/bin/sh
        set -e
        dup-backup "$@" -t initial
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
