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
        listen_addresses = "*";
        log_connections = true;
        log_statement = "all";
        logging_collector = true;
        log_disconnections = true;
        log_destination = "stderr,csvlog";
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
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = cfg.package;
      port = cfg.port;
      dataDir = cfg.dataDir;
      authentication = cfg.authentication;
      settings = cfg.settings;
      initdbArgs = cfg.initdbArgs;
      extraPlugins = cfg.extraPlugins;
      ensureDatabases = cfg.ensureDatabases;
      ensureUsers = cfg.ensureUsers;

      # Load environment file for secrets
      environmentFile = config.sops.templates."postgresql.env".path;
    };

    # Firewall configuration
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    # Ensure data directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 postgres postgres -"
    ];
  };
}
