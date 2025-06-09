{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.duplicacy;
  repoIds = [ "nas" "media-config" ];

  systemdGroupName = "duplicacy-secrets";

  escapeStringForShellDoubleQuotes =
    str: lib.replaceChars [ "\\" "\"" "$" "`" ] [ "\\\\" "\\\"" "\\$" "\\\`" ] str;

  dupLogScript = pkgs.writeShellScriptBin "dup-log" ''
    #!/bin/sh
    # Lists logs for the main duplicacy backup service.
    # For init/restore logs, use: journalctl -fu duplicacy-init-REPO_KEY.service or duplicacy-restore-REPO_KEY.service
    journalctl -fu duplicacy.service
  '';

  dupActivateScript = pkgs.writeShellScriptBin "dup-activate" ''
    #!/bin/sh
    set -e
    # Start the duplicacy timer to run backups
    echo "Activating Duplicacy timer (system-wide)..."
    systemctl start duplicacy.timer
    echo "Timer duplicacy.timer started."
    echo "Run 'dup-status' to check its status."
  '';

  dupStatusScript = pkgs.writeShellScriptBin "dup-status" ''
    #!/bin/sh
    # Show the status of the duplicacy timer
    echo "Status of Duplicacy timer (system-wide):"
    systemctl list-timers duplicacy.timer
  '';

  makeDupBackupScript =
    pkgs: cfg':
    pkgs.writeShellScriptBin "dup-backup" ''
      #!/bin/sh
      set -e

      REPO_KEYS_LIST=(${lib.concatStringsSep " " (lib.attrNames cfg'.repos)})
      ALLOWED_REPO_KEYS_STR="${lib.concatStringsSep ", " (lib.attrNames cfg'.repos)}"
      USAGE_HINT=$(if [ ''${#REPO_KEYS_LIST[@]} -eq 0 ]; then
        echo "No repositories configured in system.modules.duplicacy.repos."
      else
        echo "Allowed REPO_KEYs are: $ALLOWED_REPO_KEYS_STR"
      fi)

      if [ -z "$1" ]; then
        echo "Usage: $0 REPO_KEY [--restore] [duplicacy_init_options]"
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
          LOCAL_REPO_PATH="${escapeStringForShellDoubleQuotes cfg'.repos."${key}".localRepoPath}"
          ;;
      '') (lib.attrNames cfg'.repos)}
        *)
          echo "Error: Invalid REPO_KEY '$REPO_KEY'."
          echo "$USAGE_HINT"
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
      echo 'Args: ${cfg.defaultBackupArgs} "$@"'
      ${pkgs.duplicacy}/bin/duplicacy backup ${cfg.defaultBackupArgs} "$@"
    '';

  makeDupRestoreScript =
    pkgs: cfg':
    pkgs.writeShellScriptBin "dup-restore" ''
      #!/bin/sh
      set -e

      REPO_KEYS_LIST=(${lib.concatStringsSep " " (lib.attrNames cfg'.repos)})
      ALLOWED_REPO_KEYS_STR="${lib.concatStringsSep ", " (lib.attrNames cfg'.repos)}"
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
          LOCAL_REPO_PATH="${escapeStringForShellDoubleQuotes cfg'.repos."${key}".localRepoPath}"
          ;;
      '') (lib.attrNames cfg'.repos)}
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
    '';

  makeDupInitScript =
    pkgs: cfg':
    pkgs.writeShellScriptBin "dup-init" ''
      #!/bin/sh
      set -e

      REPO_KEYS_LIST=(${lib.concatStringsSep " " (lib.attrNames cfg'.repos)})
      ALLOWED_REPO_KEYS_STR="${lib.concatStringsSep ", " (lib.attrNames cfg'.repos)}"
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
          REPO_ID_VAL="${escapeStringForShellDoubleQuotes cfg'.repos."${key}".repoId}"
          LOCAL_REPO_PATH="${escapeStringForShellDoubleQuotes cfg'.repos."${key}".localRepoPath}"
          STORAGE_PATH_VAL="${escapeStringForShellDoubleQuotes cfg'.repos."${key}".storagePath}"
          ;;
      '') (lib.attrNames cfg'.repos)}
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
        echo "Info: Target directory '$LOCAL_REPO_PATH' for initialization (derived from REPO_KEY '$REPO_KEY') does not exist. Creating it."
        mkdir -p "$LOCAL_REPO_PATH" || { echo "Error: Failed to create directory '$LOCAL_REPO_PATH'"; exit 1; }
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
    '';

  dupBackupScript = makeDupBackupScript pkgs cfg;
  dupRestoreScript = makeDupRestoreScript pkgs cfg;
  dupInitScript = makeDupInitScript pkgs cfg;

  dupBackupInitScript = pkgs.writeShellScriptBin "dup-backup-init" ''
    #!/bin/sh
    set -e
    # This script assumes dup-backup is in PATH.
    dup-backup "$@" -t initial
  '';

in
{
  options.modules.duplicacy = {
    # Just installs duplicacy and basic scripts
    enable = lib.mkEnableOption "duplicacy";
    autoBackupCron = lib.mkOption {
      type = lib.types.str;
      default = "Mon *-*-* 05:00:00 America/New_York";
      description = "The cron schedule for automatic backups. Only used if autoBackup is enabled.";
    };
    defaultBackupArgs = lib.mkOption {
      type = lib.types.str;
      default = "-limit-rate 25000 -max-in-memory-entries 1024 -threads 4 -stats";
      description = "Default arguments for backup and restore operations.";
    };
    defaultRestoreArgs = lib.mkOption {
      type = lib.types.str;
      default = "-limit-rate 100000 -threads 4 -stats";
      description = "Default arguments for backup and restore operations.";
    };
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
                description = "Automatically init and restore the repository";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable (
    let
      # Will return a subset of cfg.repos
      filterRepos = pred: lib.filterAttrs (name: repoCfg: pred repoCfg) cfg.repos;
      reposWithAutoBackup = filterRepos (repoCfg: repoCfg.autoBackup);
      reposWithAutoInit = filterRepos (repoCfg: repoCfg.autoInit);
      reposWithAutoInitRestore = filterRepos (repoCfg: repoCfg.autoInitRestore);

      # Assertion: autoInit and autoInitRestore must not both be enabled for the same repo
      _ = lib.forEach (lib.attrNames cfg.repos) (
        repoKey:
        let
          repoCfgItem = cfg.repos."${repoKey}";
        in
        if repoCfgItem.autoInit && repoCfgItem.autoInitRestore then
          throw "Duplicacy repository '${repoKey}' cannot have both autoInit and autoInitRestore enabled at the same time. They are mutually exclusive."
        else
          null
      );

      initServices = (
        lib.mapAttrs' (
          repoKey: repoCfgItem:
          lib.nameValuePair "duplicacyInit-${repoKey}" {
            description = "Initialize Duplicacy repository ${repoKey}";
            wantedBy = [ "multi-user.target" ]; # Start at boot
            # after = [ "network-online.target" ];
            # requires = [ "network-online.target" ];
            restartIfChanged = false;
            reloadIfChanged = false;
            serviceConfig = {
              Type = "simple"; # oneshot blocks nix-rebuild
              RemainAfterExit = true; # Needed for restartIfChanged
              Group = systemdGroupName;
              WorkingDirectory = repoCfgItem.localRepoPath;
              ExecStart = "${dupInitScript}/bin/dup-init ${escapeStringForShellDoubleQuotes repoKey}";
              EnvironmentFile = config.sops.templates.duplicacyConf.path;
            };
          }
        ) reposWithAutoInit
      );
      initRestoreServices = (
        lib.mapAttrs' (
          repoKey: repoCfgItem:
          lib.nameValuePair "duplicacyInitRestore-${repoKey}" {
            description = "Restore Duplicacy repository ${repoKey} after initialization";
            wantedBy = [ "multi-user.target" ];
            # after = [ "network-online.target" ];
            # requires = [ "network-online.target" ];
            restartIfChanged = false;
            reloadIfChanged = false;
            serviceConfig = {
              Type = "simple"; # oneshot blocks nix-rebuild
              RemainAfterExit = true; # Needed for restartIfChanged
              Group = systemdGroupName;
              WorkingDirectory = repoCfgItem.localRepoPath;
              ExecStart = "${dupInitScript}/bin/dup-init ${escapeStringForShellDoubleQuotes repoKey} --restore";
              EnvironmentFile = config.sops.templates.duplicacyConf.path;
            };
          }
        ) reposWithAutoInitRestore
      );

      backupServices =
        if reposWithAutoBackup != { } then
          {
            "duplicacy" = {
              description = "Duplicacy backup service (runs backups for all autoBackup repos)";
              wantedBy = [ "multi-user.target" ]; # Start at boot
              after = [ "network-online.target" ];
              requires = [ "network-online.target" ];
              serviceConfig = {
                Type = "oneshot";
                Restart = "no";
                Group = systemdGroupName;
                ExecStart = pkgs.writeShellScript "run-duplicacy-auto-backups" ''
                  #!/bin/sh
                  set -e
                  echo "Starting Duplicacy auto-backups..."
                  ${lib.concatMapStringsSep "\n" (repoKey: ''
                    echo "Backing up repository: ${escapeStringForShellDoubleQuotes repoKey}"
                    ${dupBackupScript}/bin/dup-backup "${escapeStringForShellDoubleQuotes repoKey}"
                  '') (lib.attrNames reposWithAutoBackup)}
                  echo "Duplicacy auto-backups finished."
                '';
                EnvironmentFile = config.sops.templates.duplicacyConf.path;
              };
            };
          }
        else
          { };
    in
    {
      environment.systemPackages = with pkgs; [
        duplicacy

        dupLogScript
        dupActivateScript
        dupStatusScript
        dupBackupScript
        dupRestoreScript
        dupInitScript
        dupBackupInitScript
      ];

      # modules.nix = {
      #   unfreePackages = [ "duplicacy" ];
      # };

      # https://forum.duplicacy.com/t/duplicacy-quick-start-cli/1101
      # https://forum.duplicacy.com/t/encryption-of-the-storage/1085
      systemd.services = lib.attrsets.mergeAttrsList [
        initServices
        initRestoreServices
        backupServices
      ];

      systemd.timers.duplicacy = lib.mkIf (reposWithAutoBackup != { }) {
        Unit.Description = "Timer for Duplicacy backup service";
        Timer = {
          Unit = "duplicacy.service";
          OnCalendar = cfg.autoBackupCron;
          Persistent = true; # Catch up on missed runs
        };
        Install.WantedBy = [ "timers.target" ];
      };

      sops =
        lib.mkIf (reposWithAutoBackup != { } || reposWithAutoInit != { } || reposWithAutoInitRestore != { })
          {
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
                mode = "0440"; # Readable by owner/group
                group = systemdGroupName;
                content = ''
                  DUPLICACY_B2_ID=${config.sops.placeholder.duplicacyB2Id}
                  DUPLICACY_B2_KEY=${config.sops.placeholder.duplicacyB2Key}
                  DUPLICACY_PASSWORD=${config.sops.placeholder.duplicacyPassword}
                  BUCKET_NAME=${config.sops.placeholder.duplicacyB2Bucket}
                '';
                # Reload duplicacy.service if it exists when secrets change
                reloadUnits = lib.mkIf (reposWithAutoBackup != { }) [ "duplicacy.service" ];
              };
            };
          };

      users.groups.${systemdGroupName} = { };
    }
  );
}
