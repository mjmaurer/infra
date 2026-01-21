{
  config,
  lib,
  username,
  mylib,
  pkgs,
  ...
}:
let
  cfg = config.modules.duplicacy;
  # Also need to add as a group at the end of the file
  repoIds = [
    "nas"
    "karaoke"
    "media-config"
    "maple-garage"
  ];

  systemdGroupName = "duplicacy-secrets";

  escapeStringForShellDoubleQuotes =
    str: lib.replaceStrings [ "\\" "\"" "$" "`" ] [ "\\\\" "\\\"" "\\$" "\\\`" ] str;

  # Import scripts from separate files
  dupBackupScript = import ./scripts/dup-backup.nix {
    inherit
      pkgs
      lib
      cfg
      escapeStringForShellDoubleQuotes
      ;
  };
  dupRestoreScript = import ./scripts/dup-restore.nix {
    inherit
      pkgs
      lib
      cfg
      escapeStringForShellDoubleQuotes
      ;
  };
  dupInitScript = import ./scripts/dup-init.nix {
    inherit
      pkgs
      lib
      cfg
      escapeStringForShellDoubleQuotes
      dupRestoreScript
      ;
  };

in
{
  options.modules.duplicacy = {
    # Just installs duplicacy and basic scripts
    enable = lib.mkEnableOption "duplicacy";
    enableServices = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "duplicacy"
      ];
    };
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
      default = { };
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
              ensureLocalPath = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.submodule {
                    options = {
                      owner = lib.mkOption {
                        type = lib.types.str;
                        default = username;
                        description = "Owner for the created directory.";
                      };
                      group = lib.mkOption {
                        type = lib.types.str;
                        default = "root";
                        description = "Group for the created directory.";
                      };
                      mode = lib.mkOption {
                        type = lib.types.str;
                        default = "0750";
                        description = "Permissions mode for the created directory.";
                      };
                    };
                  }
                );
                default = null;
                description = "Configuration for ensuring the local repository path exists.";
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
      reposWithEnsureLocal = filterRepos (repoCfg: repoCfg.ensureLocalPath != null);
      mkGroupName =
        repoId:
        if repoId == "nas" then
          "nas"
        else if repoId == "media-config" then
          "media"
        else
          repoId;

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
            wantedBy = if repoCfgItem.autoInit then [ "multi-user.target" ] else lib.mkForce [ ];
            after = [
              "network-online.target"
            ]
            ++ lib.optional (repoCfgItem.ensureLocalPath != null) "systemd-tmpfiles-resetup.service";
            requires = [
              "network-online.target"
            ]
            ++ lib.optional (repoCfgItem.ensureLocalPath != null) "systemd-tmpfiles-resetup.service";
            restartIfChanged = false;
            serviceConfig = {
              Type = "simple";
              RemainAfterExit = true;
              Group = mkGroupName repoCfgItem.repoId;
              WorkingDirectory = repoCfgItem.localRepoPath;
              ExecStart = "${dupInitScript}/bin/dup-init ${escapeStringForShellDoubleQuotes repoKey}";
              EnvironmentFile = config.sops.templates.duplicacyConf.path;
            };
          }
        ) cfg.repos
      );
      initRestoreServices = (
        lib.mapAttrs' (
          repoKey: repoCfgItem:
          lib.nameValuePair "duplicacyInitRestore-${repoKey}" {
            description = "Restore Duplicacy repository ${repoKey} after initialization";
            wantedBy = if repoCfgItem.autoInitRestore then [ "multi-user.target" ] else lib.mkForce [ ];
            after = [
              "network-online.target"
            ]
            ++ lib.optional (repoCfgItem.ensureLocalPath != null) "systemd-tmpfiles-resetup.service";
            requires = [
              "network-online.target"
            ]
            ++ lib.optional (repoCfgItem.ensureLocalPath != null) "systemd-tmpfiles-resetup.service";
            restartIfChanged = false;
            serviceConfig = {
              Type = "simple";
              RemainAfterExit = true;
              Group = mkGroupName repoCfgItem.repoId;
              WorkingDirectory = repoCfgItem.localRepoPath;
              ExecStart = "${dupInitScript}/bin/dup-init ${escapeStringForShellDoubleQuotes repoKey} --restore";
              EnvironmentFile = config.sops.templates.duplicacyConf.path;
            };
          }
        ) cfg.repos
      );
      restoreLatestServices = (
        lib.mapAttrs' (
          repoKey: repoCfgItem:
          lib.nameValuePair "duplicacyRestoreLatest-${repoKey}" {
            description = "Restore Duplicacy repository ${repoKey} after initialization";
            wantedBy = lib.mkForce [ ]; # Should be run manually
            after = [ "network-online.target" ];
            requires = [ "network-online.target" ];
            restartIfChanged = false;
            serviceConfig = {
              Type = "oneshot";
              Group = mkGroupName repoCfgItem.repoId;
              WorkingDirectory = repoCfgItem.localRepoPath;
              ExecStart = "${dupRestoreScript}/bin/dup-restore ${escapeStringForShellDoubleQuotes repoKey} --latest -hash";
              EnvironmentFile = config.sops.templates.duplicacyConf.path;
            };
          }
        ) cfg.repos
      );
      restoreLatestOverwriteServices = (
        lib.mapAttrs' (
          repoKey: repoCfgItem:
          lib.nameValuePair "duplicacyRestoreLatestOverwrite-${repoKey}" {
            description = "Restore Duplicacy repository ${repoKey} after initialization";
            wantedBy = lib.mkForce [ ]; # Should be run manually
            after = [ "network-online.target" ];
            requires = [ "network-online.target" ];
            restartIfChanged = false;
            serviceConfig = {
              Type = "oneshot";
              Group = mkGroupName repoCfgItem.repoId;
              WorkingDirectory = repoCfgItem.localRepoPath;
              ExecStart = "${dupRestoreScript}/bin/dup-restore ${escapeStringForShellDoubleQuotes repoKey} --latest -hash -overwrite";
              EnvironmentFile = config.sops.templates.duplicacyConf.path;
            };
          }
        ) cfg.repos
      );
      backupServices = (
        lib.mapAttrs' (
          repoKey: repoCfgItem:
          lib.nameValuePair "duplicacyBackup-${repoKey}" {
            description = "Backup Duplicacy repository ${repoKey}";
            wantedBy = lib.mkForce [ ]; # Should be run manually
            after = [ "network-online.target" ];
            requires = [ "network-online.target" ];
            restartIfChanged = false;
            serviceConfig = {
              Type = "oneshot";
              Group = mkGroupName repoCfgItem.repoId;
              WorkingDirectory = repoCfgItem.localRepoPath;
              ExecStart = "${dupBackupScript}/bin/dup-backup ${escapeStringForShellDoubleQuotes repoKey}";
              EnvironmentFile = config.sops.templates.duplicacyConf.path;
            };
          }
        ) cfg.repos
      );

      backupAllServices =
        if cfg.repos != { } then
          {
            "duplicacyBackupAll" = {
              description = "Duplicacy backup service (runs backups for all autoBackup repos)";
              after = [ "network-online.target" ];
              requires = [ "network-online.target" ];
              serviceConfig = {
                Type = "oneshot";
                Restart = "no";
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
    lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          duplicacy
          dupInitScript
          dupBackupScript
          dupRestoreScript
        ];

        # modules.nix = {
        #   unfreePackages = [ "duplicacy" ];
        # };

        # https://forum.duplicacy.com/t/duplicacy-quick-start-cli/1101
        # https://forum.duplicacy.com/t/encryption-of-the-storage/1085
      }
      (lib.mkIf cfg.enableServices {

        environment.systemPackages = with pkgs; [
          (pkgs.writeShellScriptBin "dup-run" ''
            #!/bin/sh
            set -e

            if [ $# -ne 2 ]; then
              echo "Usage: dup-run <repo_key> <service>"
              echo "  repo_key: The repository key"
              echo "  service: One of init, initRestore, restoreLatest, restoreLatestOverwrite, or backup"
              exit 1
            fi

            repo_key="$1"
            service="$2"

            case "$service" in
              init)
                service_name="duplicacyInit-$repo_key"
                ;;
              initRestore)
                service_name="duplicacyInitRestore-$repo_key"
                ;;
              restoreLatest)
                service_name="duplicacyRestoreLatest-$repo_key"
                ;;
              restoreLatestOverwrite)
                service_name="duplicacyRestoreLatestOverwrite-$repo_key"
                ;;
              backup)
                service_name="duplicacyBackup-$repo_key"
                ;;
              backupAll)
                service_name="duplicacyBackupAll"
                ;;
              *)
                echo "Error: Invalid service '$service'"
                echo "Service must be one of: init, initRestore, restoreLatest, restoreLatestOverwrite, backup"
                exit 1
                ;;
            esac

            echo "Starting $service_name..."
            sudo systemctl start "$service_name"
          '')
          (pkgs.writeShellScriptBin "dup-log" ''
            #!/bin/sh
            set -e

            if [ $# -ne 2 ]; then
              echo "Usage: dup-log <repo_key> <service>"
              echo "  repo_key: The repository key"
              echo "  service: One of init, initRestore, restoreLatest, restoreLatestOverwrite, backup, or backupAll"
              exit 1
            fi

            repo_key="$1"
            service="$2"

            case "$service" in
              init)
                service_name="duplicacyInit-$repo_key"
                ;;
              initRestore)
                service_name="duplicacyInitRestore-$repo_key"
                ;;
              restoreLatest)
                service_name="duplicacyRestoreLatest-$repo_key"
                ;;
              restoreLatestOverwrite)
                service_name="duplicacyRestoreLatestOverwrite-$repo_key"
                ;;
              backup)
                service_name="duplicacyBackup-$repo_key"
                ;;
              backupAll)
                service_name="duplicacyBackupAll"
                ;;
              *)
                echo "Error: Invalid service '$service'"
                echo "Service must be one of: init, initRestore, restoreLatest, restoreLatestOverwrite, backup, or backupAll"
                exit 1
                ;;
            esac

            echo "Logs for $service_name:"
            sudo systemctl status "$service_name"
            sudo journalctl -f -u "$service_name" --no-pager
          '')
        ];

        systemd.services = lib.attrsets.mergeAttrsList [
          initServices
          initRestoreServices
          restoreLatestServices
          restoreLatestOverwriteServices
          backupServices
          backupAllServices
        ];

        systemd.timers.duplicacyBackupAll = lib.mkIf (reposWithAutoBackup != { }) {
          description = "Timer for Duplicacy backup service";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            Unit = "duplicacyBackupAll.service";
            OnCalendar = cfg.autoBackupCron;
            Persistent = true; # Catch up on missed runs
          };
        };

        systemd.tmpfiles.settings = lib.mkIf (reposWithEnsureLocal != { }) {
          "duplicacy-ensure-paths" = (
            lib.mapAttrs' (
              repoKey: repoCfgItem:
              lib.nameValuePair repoCfgItem.localRepoPath {
                d = {
                  user = repoCfgItem.ensureLocalPath.owner;
                  group = repoCfgItem.ensureLocalPath.group;
                  mode = repoCfgItem.ensureLocalPath.mode;
                };
              }
            ) reposWithEnsureLocal
          );
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
              mode = "0440"; # Readable by owner(root)/group
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

        users.users.${username}.extraGroups = [
          "karaoke"
        ];
        users.groups.${systemdGroupName} = { };
        users.groups.karaoke = { };
      })
    ]
  );
}
