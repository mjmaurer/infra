{
  config,
  lib,
  username,
  pkgs,
  ...
}:
let
  cfg = config.modules.duplicacy;
  repoIds = [
    "nas"
    "media-config"
  ];

  systemdGroupName = "duplicacy-secrets";

  escapeStringForShellDoubleQuotes =
    str: lib.replaceChars [ "\\" "\"" "$" "`" ] [ "\\\\" "\\\"" "\\$" "\\\`" ] str;

  # Import scripts from separate files
  dupLogScript = import ./scripts/dup-log.nix { inherit pkgs; };
  dupActivateScript = import ./scripts/dup-activate.nix { inherit pkgs; };
  dupStatusScript = import ./scripts/dup-status.nix { inherit pkgs; };
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
  dupBackupInitScript = import ./scripts/dup-backup-init.nix { inherit pkgs; };

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
