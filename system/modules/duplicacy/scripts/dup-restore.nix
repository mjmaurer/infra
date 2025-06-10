{
  pkgs,
  lib,
  cfg,
  escapeStringForShellDoubleQuotes,
}:
pkgs.writeShellScriptBin "dup-restore" ''
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
    echo "Usage: $0 REPO_KEY [--latest] [duplicacy_options]"
    echo "Error: REPO_KEY is required."
    echo "$USAGE_HINT"
    echo ""
    echo "Options:"
    echo "  --latest    Automatically retrieve and restore the latest revision"
    exit 1
  fi

  REPO_KEY="$1"
  shift # Remove REPO_KEY from arguments

  # Check for --latest flag
  USE_LATEST=false
  if [ "$1" = "--latest" ]; then
    USE_LATEST=true
    shift # Remove --latest from arguments
  fi

  LOCAL_REPO_PATH=""
  REPO_ID_VAL=""

  case "$REPO_KEY" in
  ${lib.concatMapStringsSep "\n" (key: ''
    "${key}")
      LOCAL_REPO_PATH="${escapeStringForShellDoubleQuotes cfg.repos."${key}".localRepoPath}"
      REPO_ID_VAL="${cfg.repos."${key}".repoId}"
      ;;
  '') (lib.attrNames cfg.repos)}
    *)
      echo "Error: Invalid REPO_KEY '$REPO_KEY'."
      echo "$USAGE_HINT"
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

  # If --latest flag is used, retrieve the latest revision
  if [ "$USE_LATEST" = true ]; then
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
      echo "Error: No snapshot revisions found for repository ID '$REPO_ID_VAL'."
      echo "Cannot restore without any available snapshots."
      exit 1
    fi
    
    echo "Latest revision ID for '$REPO_ID_VAL' is '$LATEST_REV_ID'."
    echo "Running restore for repository in '$PWD' (REPO_KEY: '$REPO_KEY') with revision '$LATEST_REV_ID'..."
    echo 'Args: ${cfg.defaultRestoreArgs} -r "$LATEST_REV_ID" "$@"'
    ${pkgs.duplicacy}/bin/duplicacy restore ${cfg.defaultRestoreArgs} -r "$LATEST_REV_ID" "$@"
  else
    echo "Running restore for repository in '$PWD' (REPO_KEY: '$REPO_KEY')..."
    echo 'Args: ${cfg.defaultRestoreArgs} "$@"'
    ${pkgs.duplicacy}/bin/duplicacy restore ${cfg.defaultRestoreArgs} "$@"
  fi
''
