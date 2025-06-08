{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.duplicacy;
  repoIds = [ "nas" ];

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
        echo "Error: Target directory '$LOCAL_REPO_PATH' for backup (derived from REPO_KEY '$REPO_KEY') does not exist or is not a directory. Run dup-init first."
        exit 1
      fi

      cd "$LOCAL_REPO_PATH" || { echo "Error: Failed to cd into '$LOCAL_REPO_PATH'"; exit 1; }

      if [ ! -d ".duplicacy" ]; then
        echo "Error: .duplicacy folder not found in '$LOCAL_REPO_PATH'. Please initialize the repository first (e.g. using dup-init '$REPO_KEY')."
        exit 1
      fi

      echo "Running backup for repository in '$PWD' (REPO_KEY: '$REPO_KEY')..."
      ${pkgs.duplicacy}/bin/duplicacy backup ${cfg.defaultBackupAndRestoreArgs} "$@"
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
      ${pkgs.duplicacy}/bin/duplicacy restore ${cfg.defaultBackupAndRestoreArgs} "$@"
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

      ACTUAL_STORAGE_URL=$(eval echo "$STORAGE_PATH_VAL")

      if [ ! -d "$LOCAL_REPO_PATH" ]; then
        echo "Info: Target directory '$LOCAL_REPO_PATH' for initialization (derived from REPO_KEY '$REPO_KEY') does not exist. Creating it."
        mkdir -p "$LOCAL_REPO_PATH" || { echo "Error: Failed to create directory '$LOCAL_REPO_PATH'"; exit 1; }
      fi

      cd "$LOCAL_REPO_PATH" || { echo "Error: Failed to cd into '$LOCAL_REPO_PATH'"; exit 1; }

      if [ -d ".duplicacy" ]; then
        echo "Info: .duplicacy directory already exists in '$LOCAL_REPO_PATH'. Repository is already initialized."
        exit 0
      fi

      echo "Initializing Duplicacy repository '$REPO_ID_VAL' in '$PWD' (REPO_KEY: '$REPO_KEY')..."
      echo "Storage URL: '$ACTUAL_STORAGE_URL'"

      if [ -z "$DUPLICACY_PASSWORD" ]; then
          echo "Warning: DUPLICACY_PASSWORD is not set in the environment."
          echo "Duplicacy may prompt for it, or you can set it (e.g., via sops)."
      fi

      ${pkgs.duplicacy}/bin/duplicacy init -encrypt -zstd "$REPO_ID_VAL" "$ACTUAL_STORAGE_URL" "$@"
      echo "Repository '$REPO_ID_VAL' initialized in '$PWD'."
      echo "You may want to run an initial backup using a command like: dup-backup-init $REPO_KEY"
    '';

  # Scripts that depend on other scripts (like dup-backup-init depends on dup-backup)
  # need to ensure the called script is on PATH or use its full path.
  # For simplicity, environment.systemPackages will put them all on PATH.
  # Note: dupBackupScript needs to be defined before dupBackupInitScript if it were to use the Nix attr path.
  # However, dup-backup-init calls `dup-backup` assuming it's in PATH.
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
    defaultBackupAndRestoreArgs = lib.mkOption {
      type = lib.types.str;
      default = "-limit-rate 25000 -max-in-memory-entries 1024 -threads 4 -stats";
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
                description = "Automatically restore the repository after init";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable (
    let
      filterRepos = pred: lib.filterAttrs (name: repoCfg: pred repoCfg) cfg.repos;
      reposWithAutoBackup = filterRepos (repoCfg: repoCfg.autoBackup);
      reposWithAutoInit = filterRepos (repoCfg: repoCfg.autoInit);
      reposWithAutoInitRestore = filterRepos (repoCfg: repoCfg.autoInitRestore);

      # Assertion for autoInitRestore without autoInit
      _ = lib.forEach (lib.attrNames cfg.repos) (
        repoKey:
        let
          repoCfgItem = cfg.repos."${repoKey}";
        in
        if repoCfgItem.autoInitRestore && !repoCfgItem.autoInit then
          throw "Duplicacy repository '${repoKey}' has autoInitRestore enabled but autoInit is disabled. This is not allowed."
        else
          null
      );
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
      systemd.services =
        (lib.mkIf (reposWithAutoBackup != { }) {
          "duplicacy" = {
            Unit.Description = "Duplicacy backup service (runs backups for all autoBackup repos)";
            After = [
              "network-online.target"
              "sops.service"
            ];
            Requires = [ "sops.service" ];
            wantedBy = [ "multi-user.target" ]; # Start at boot
            Service = {
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
        })
        // (lib.mapAttrs' (
          repoKey: repoCfgItem:
          lib.nameValuePair "duplicacy-init-${repoKey}" {
            description = "Initialize Duplicacy repository ${repoKey}";
            wantedBy = [ "multi-user.target" ]; # Start at boot
            after = [
              "network-online.target"
              "sops.service"
            ];
            requires = [
              "network-online.target"
              "sops.service"
            ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true; # Important for dependencies
              Group = systemdGroupName;
              WorkingDirectory = repoCfgItem.localRepoPath;
              ExecStart = "${dupInitScript}/bin/dup-init ${escapeStringForShellDoubleQuotes repoKey}";
              EnvironmentFile = config.sops.templates.duplicacyConf.path;
            };
          }
        ) reposWithAutoInit)
        // (lib.mapAttrs' (
          repoKey: repoCfgItem:
          lib.nameValuePair "duplicacy-restore-${repoKey}" {
            description = "Restore Duplicacy repository ${repoKey} after initialization";
            wantedBy = [ "multi-user.target" ];
            after = [
              "duplicacy-init-${repoKey}.service"
              "sops.service"
            ];
            requires = [
              "duplicacy-init-${repoKey}.service"
              "sops.service"
            ];
            serviceConfig = {
              Type = "oneshot";
              Group = systemdGroupName;
              WorkingDirectory = repoCfgItem.localRepoPath;
              ExecStart = "${dupRestoreScript}/bin/dup-restore ${escapeStringForShellDoubleQuotes repoKey}";
              EnvironmentFile = config.sops.templates.duplicacyConf.path;
            };
          }
        ) reposWithAutoInitRestore);

      systemd.timers.duplicacy = lib.mkIf (reposWithAutoBackup != { }) {
        Unit.Description = "Timer for Duplicacy backup service";
        Timer = {
          Unit = "duplicacy.service";
          OnCalendar = cfg.autoBackupCron;
          Persistent = true; # Catch up on missed runs
        };
        Install.WantedBy = [ "timers.target" ];
      };

      sops = lib.mkIf (reposWithAutoBackup != { }) {
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
            # Restart duplicacy.service if it exists when secrets change
            restartUnits = "duplicacy.service";
          };
        };
      };

      users.groups.${systemdGroupName} = { };
    }
  );
}
