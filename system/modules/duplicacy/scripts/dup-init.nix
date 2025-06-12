{
  pkgs,
  lib,
  cfg,
  escapeStringForShellDoubleQuotes,
  dupRestoreScript,
}:
pkgs.writeShellScriptBin "dup-init" ''
  #!/bin/sh
  set -e

  REPO_KEYS_LIST=(${lib.concatStringsSep " " (lib.attrNames cfg.repos)})
  ALLOWED_REPO_KEYS_STR="${lib.concatStringsSep ", " (lib.attrNames cfg.repos)}"
  USAGE_HINT=$(if [ ''${#REPO_KEYS_LIST[@]} -eq 0 ]; then
    echo "No repositories configured in system.modules.duplicacy.repos."
  else
    echo "Allowed REPO_KEYs are: $ALLOWED_REPO_KEYS_STR"
  fi)

  if [ -z "$1" ]; then
    echo "Usage: $0 REPO_KEY [duplicacy_options]"
    echo "Error: REPO_KEY is required."
    echo "$USAGE_HINT"
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
  '') (lib.attrNames cfg.repos)}
    *)
      echo "Error: Invalid REPO_KEY '$REPO_KEY'."
      echo "$USAGE_HINT"
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

  # Parse --restore flag and collect other arguments for duplicacy init
  RESTORE_AFTER_INIT=false
  PASSTHRU_INIT_ARGS=()
  for arg_opt in "$@"; do
    if [ "$arg_opt" = "--restore" ]; then
      RESTORE_AFTER_INIT=true
    else
      PASSTHRU_INIT_ARGS+=("$arg_opt")
    fi
  done

  ACTUAL_STORAGE_URL=$(eval echo "$STORAGE_PATH_VAL")

  if [ ! -d "$LOCAL_REPO_PATH" ]; then
    echo "Error: Target directory '$LOCAL_REPO_PATH' for initialization (derived from REPO_KEY '$REPO_KEY') does not exist."
    echo "Please create it manually or ensure the path is correct."
    exit 1
  fi

  cd "$LOCAL_REPO_PATH" || { echo "Error: Failed to cd into '$LOCAL_REPO_PATH'"; exit 1; }

  WAS_NEWLY_INITIALIZED=false
  if [ -d ".duplicacy" ]; then
    echo "Info: .duplicacy directory already exists in '$LOCAL_REPO_PATH'. Repository is already initialized. Exiting."
    exit 0
  else
    echo "Initializing Duplicacy repository '$REPO_ID_VAL' in '$PWD' (REPO_KEY: '$REPO_KEY')..."
    echo "Storage URL: '$ACTUAL_STORAGE_URL'"

    if [ -z "$DUPLICACY_PASSWORD" ]; then
        echo "Warning: DUPLICACY_PASSWORD is not set in the environment."
        echo "Duplicacy may prompt for it, or you can set it (e.g., via sops)."
    fi

    # Use PASSTHRU_INIT_ARGS which have --restore filtered out
    ${pkgs.duplicacy}/bin/duplicacy init -encrypt -zstd "$REPO_ID_VAL" "$ACTUAL_STORAGE_URL" "''${PASSTHRU_INIT_ARGS[@]}"
    echo "Repository '$REPO_ID_VAL' initialized in '$PWD'."
    WAS_NEWLY_INITIALIZED=true
  fi

  if [ "$RESTORE_AFTER_INIT" = true ]; then
    echo "Restore requested. Attempting to restore latest revision for '$REPO_ID_VAL' in '$PWD' (REPO_KEY: '$REPO_KEY')..."
    
    # Ensure .duplicacy exists. This check is vital if init was skipped or if init failed silently (though set -e should prevent silent failure).
    if [ ! -d ".duplicacy" ]; then
      echo "Error: .duplicacy folder not found in '$LOCAL_REPO_PATH'. This should not happen if initialization was successful or skipped."
      echo "Cannot proceed with restore."
      exit 1 
    fi

    echo "Fetching list of snapshots for repository ID '$REPO_ID_VAL'..."
    
    # Run duplicacy list in the repository directory. Credentials must be in environment.
    LIST_OUTPUT_ERR=$(${pkgs.duplicacy}/bin/duplicacy list 2>&1)
    LIST_STATUS=$?

    if [ $LIST_STATUS -ne 0 ]; then
        echo "Error: 'duplicacy list' command failed with status $LIST_STATUS."
        echo "Output:"
        echo "$LIST_OUTPUT_ERR"
        exit 1 
    fi
    
    # Filter for "Snapshot $REPO_ID_VAL revision ...", get last line, extract 4th field (revision number)
    LATEST_REV_ID=$(echo "$LIST_OUTPUT_ERR" | grep "Snapshot $REPO_ID_VAL revision" | tail -n 1 | ${pkgs.gawk}/bin/awk '{print $4}')

    if [ -z "$LATEST_REV_ID" ]; then
      echo "Info: No snapshot revisions found for repository ID '$REPO_ID_VAL' matching 'Snapshot $REPO_ID_VAL revision ...'."
      echo "Skipping restore. This is normal for a brand new repository or if no backups have run yet."
    else
      echo "Latest revision ID for '$REPO_ID_VAL' is '$LATEST_REV_ID'."
      echo "Calling dup-restore for REPO_KEY '$REPO_KEY' with revision '$LATEST_REV_ID'..."
      if ${dupRestoreScript}/bin/dup-restore "$REPO_KEY" -r "$LATEST_REV_ID"; then
        echo "Restore completed successfully."
      else
        # set -e is active, so script will exit. This message provides context.
        echo "Error: dup-restore command failed during the --restore process."
        exit 1 
      fi
    fi
  elif [ "$WAS_NEWLY_INITIALIZED" = true ]; then
    # This message is shown only if newly initialized AND --restore was NOT requested.
    echo "You may want to run an initial backup using a command like: dup-backup-init $REPO_KEY"
  fi
''
