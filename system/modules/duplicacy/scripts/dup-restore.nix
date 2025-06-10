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
    echo "Usage: $0 REPO_KEY [duplicacy_options]"
    echo "Error: REPO_KEY is required."
    echo "$USAGE_HINT"
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

  echo "Running restore for repository in '$PWD' (REPO_KEY: '$REPO_KEY')..."
  echo 'Args: ${cfg.defaultRestoreArgs} "$@"'
  ${pkgs.duplicacy}/bin/duplicacy restore ${cfg.defaultRestoreArgs} "$@"
''
