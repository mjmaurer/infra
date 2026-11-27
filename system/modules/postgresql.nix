{
  lib,
  config,
  derivationName,
  mylib,
  pkgs,
  ...
}:
let
  cfg = config.modules.postgresql;
  pg = config.services.postgresql.package;
  appDatabases = lib.attrNames cfg.databases;
in
{
  options.modules.postgresql = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "postgresql"
      ];
    };

    package = lib.mkPackageOption pkgs "postgresql" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5432;
      description = "Port for PostgreSQL server";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/postgresql";
      description = "Data directory for PostgreSQL";
    };

    authentication = lib.mkOption {
      type = lib.types.str;
      default = lib.concatStringsSep "\n" [
        "local all all                              trust"
        "host  all all 127.0.0.1/32                 scram-sha-256"
        "host  all all ::1/128                      scram-sha-256"
        "host  all all ${config.modules.networking.tailscaleIPRange} scram-sha-256"
      ];
      description = "PostgreSQL authentication configuration (pg_hba.conf)";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.str
          lib.types.int
          lib.types.bool
        ]
      );
      default = {
        log_connections = true;
        log_statement = "all";
        logging_collector = true;
        log_disconnections = true;
        timezone = "UTC";
      };
      description = "PostgreSQL configuration settings";
    };

    initdbArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--locale=C"
        "--encoding=UTF8"
      ];
      description = "Additional arguments passed to initdb during initial database creation";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open firewall port for PostgreSQL";
    };

    extraPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional PostgreSQL plugins/extensions to install";
    };

    ensureDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of databases to ensure exist (created if they don't exist)";
    };

    ensureUsers = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Name of the user";
            };
            ensureDBOwnership = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to ensure this user owns databases with the same name";
            };
          };
        }
      );
      default = [ ];
      description = "List of users to ensure exist";
    };

    databases = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.passwordFile = lib.mkOption {
            type = lib.types.str;
            description = ''
              File holding the user's password (e.g. a sops secret). Must be readable by the
              postgres user (sops: owner = "postgres").
            '';
          };
        }
      );
      default = { };
      example = lib.literalExpression ''
        { myapp.passwordFile = config.sops.secrets.myappPostgresPassword.path; }
      '';
      description = ''
        App databases. Each gets a database and a login user of the same name that owns it,
        with its password set from passwordFile (re-applied on every start of
        postgresql-databases.service, so rotating the secret just works). Each user can connect
        only to its own database. Services using one should order after
        postgresql-databases.service.
      '';
    };

    backup = {
      enable = lib.mkEnableOption "nightly pg_dump of every database";
      dir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/postgresql-backups";
        description = "Where dumps are written (<database>-<date>.dump, pg_dump custom format).";
      };
      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 04:30:00";
        description = "systemd OnCalendar expression for the dump.";
      };
      keepDays = lib.mkOption {
        type = lib.types.int;
        default = 14;
        description = "Dumps older than this many days are deleted.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      enableTCPIP = true;
      package = cfg.package;
      dataDir = cfg.dataDir;
      authentication = cfg.authentication;
      settings = cfg.settings // {
        port = cfg.port;
      };
      initdbArgs = cfg.initdbArgs;
      extensions = cfg.extraPlugins;
      ensureDatabases = cfg.ensureDatabases ++ appDatabases;
      ensureUsers =
        cfg.ensureUsers
        ++ map (name: {
          inherit name;
          ensureDBOwnership = true;
        }) appDatabases;
      initialScript = config.sops.templates.postgresInitScript.path;
    };

    sops = {
      templates = {
        "postgresInitScript" = {
          owner = config.users.users.postgres.name;
          content = ''
            alter user postgres with password '${config.sops.placeholder.postgresPassword}';

          '';
          # Newlines in 'content' are needed!
        };
      };
    };

    # Sets app database passwords and limits each app user to its own database. Statement
    # logging is off for this session so passwords don't end up in Postgres's log.
    systemd.services.postgresql-databases = lib.mkIf (appDatabases != [ ]) {
      description = "Set PostgreSQL app database passwords and access";
      after = [ "postgresql-setup.service" ];
      requires = [ "postgresql-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "postgres";
      };
      script = ''
        ${pg}/bin/psql -v ON_ERROR_STOP=1 -p ${toString cfg.port} -d postgres \
          ${
            lib.concatMapStringsSep " " (
              name: ''-v ${name}="$(cat ${cfg.databases.${name}.passwordFile})"''
            ) appDatabases
          } <<'SQL'
        SET log_statement = 'none';
        ${lib.concatMapStrings (name: ''
          ALTER ROLE "${name}" WITH LOGIN PASSWORD :'${name}';
          REVOKE CONNECT ON DATABASE "${name}" FROM PUBLIC;
          GRANT CONNECT ON DATABASE "${name}" TO "${name}";
        '') appDatabases}
        SQL
      '';
    };

    systemd.services.postgresql-backup = lib.mkIf cfg.backup.enable {
      description = "Dump every PostgreSQL database";
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
      };
      script = ''
        set -euo pipefail
        dbs=$(${pg}/bin/psql -p ${toString cfg.port} -d postgres -tAc \
          "SELECT datname FROM pg_database WHERE NOT datistemplate")
        for db in $dbs; do
          ${pg}/bin/pg_dump -p ${toString cfg.port} -Fc "$db" > "${cfg.backup.dir}/$db-$(date +%F).dump"
        done
        ${pkgs.findutils}/bin/find ${cfg.backup.dir} -name '*.dump' -mtime +${toString cfg.backup.keepDays} -delete
      '';
    };
    systemd.timers.postgresql-backup = lib.mkIf cfg.backup.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.backup.onCalendar;
        Persistent = true;
      };
    };

    # Firewall configuration
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    # Ensure data directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 postgres postgres -"
    ]
    ++ lib.optional cfg.backup.enable "d ${cfg.backup.dir} 0700 postgres postgres -";
  };
}
