{
  lib,
  config,
  derivationName,
  mylib,
  pkgs,
  ...
}:
let
  cfg = config.modules.garage;
in
{
  options.modules.garage = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "garage"
      ];
    };

    package = lib.mkPackageOption pkgs "garage_2" { };

    logLevel = lib.mkOption {
      type = lib.types.enum [
        "error"
        "warn"
        "info"
        "debug"
        "trace"
      ];
      default = "info";
      description = "Garage log level";
    };

    rootDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/garage";
      description = "Root directory for Garage data and metadata";
    };

    replicationMode = lib.mkOption {
      type = lib.types.str;
      default = "1";
      description = "Replication mode (1, 2, 3, or 1-4-8)";
    };

    duplicacy = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Duplicacy integration for Garage backups";
      };
      repoName = lib.mkOption {
        type = lib.types.str;
        default = "${derivationName}-garage";
        description = "Name of the Duplicacy repository for Garage backups";
      };
    };

    ports = {
      rpc = lib.mkOption {
        type = lib.types.port;
        default = 3901;
        description = "Port for RPC communication";
      };

      s3 = lib.mkOption {
        type = lib.types.port;
        default = 3900;
        description = "Port for S3 API";
      };

      web = lib.mkOption {
        type = lib.types.port;
        default = 3902;
        description = "Port for S3 web interface";
      };

      admin = lib.mkOption {
        type = lib.types.port;
        default = 3903;
        description = "Port for admin API";
      };

      k2v = lib.mkOption {
        type = lib.types.port;
        default = 3904;
        description = "Port for K2V API";
      };

      webui = lib.mkOption {
        type = lib.types.port;
        default = 3909;
        description = "Port for Garage Web UI";
      };
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "IP address for services and RPC communication";
    };

    s3Region = lib.mkOption {
      type = lib.types.str;
      default = "us-east-1";
      description = "S3 region name";
    };

    domains = {
      s3 = lib.mkOption {
        type = lib.types.str;
        default = ".s3.garage";
        description = "Root domain for S3 API virtual-hosted-style requests";
      };

      web = lib.mkOption {
        type = lib.types.str;
        default = ".web.garage";
        description = "Root domain for S3 web interface";
      };
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra environment variables to pass to Garage server";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open firewall ports for Garage services";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional Garage configuration settings";
    };

    webui = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Garage Web UI";
      };

      package = lib.mkPackageOption pkgs "garage-webui" { };

      extraEnvironment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Extra environment variables to pass to Garage Web UI";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    modules.duplicacy = lib.mkIf cfg.duplicacy.enable {
      enableServices = true;
      repos = {
        ${cfg.duplicacy.repoName} = {
          repoId = cfg.duplicacy.repoName;
          localRepoPath = cfg.rootDir;
          autoInit = true;
          autoBackup = true;
        };
      };
    };

    services.garage = {
      enable = true;
      package = cfg.package;
      logLevel = cfg.logLevel;
      environmentFile = config.sops.templates."garage.env".path;
      extraEnvironment = cfg.extraEnvironment;

      settings = lib.recursiveUpdate {
        metadata_dir = "${cfg.rootDir}/meta";
        data_dir = "${cfg.rootDir}/data";
        db_engine = "sqlite";

        replication_factor = 1;
        consistency_mode = "consistent";
        compression_level = 1;

        rpc_bind_addr = "${cfg.address}:${toString cfg.ports.rpc}";
        rpc_public_addr = "${cfg.address}:${toString cfg.ports.rpc}";

        s3_api = {
          s3_region = cfg.s3Region;
          api_bind_addr = "${cfg.address}:${toString cfg.ports.s3}";
          root_domain = cfg.domains.s3;
        };

        s3_web = {
          bind_addr = "${cfg.address}:${toString cfg.ports.web}";
          root_domain = cfg.domains.web;
          index = "index.html";
        };

        k2v_api = {
          api_bind_addr = "${cfg.address}:${toString cfg.ports.k2v}";
        };

        admin = {
          api_bind_addr = "${cfg.address}:${toString cfg.ports.admin}";
        };
      } cfg.extraSettings;
    };

    # Garage Web UI service
    systemd.services.garage-webui = lib.mkIf cfg.webui.enable {
      description = "Garage Web UI";
      after = [
        "network.target"
        "garage.service"
      ];
      wants = [ "garage.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = lib.recursiveUpdate {
        PORT = toString cfg.ports.webui;
        CONFIG_PATH = "/etc/garage.toml";
        API_BASE_URL = "http://127.0.0.1:${toString cfg.ports.admin}";
        S3_ENDPOINT_URL = "http://127.0.0.1:${toString cfg.ports.s3}";
        S3_REGION = cfg.s3Region;
      } cfg.webui.extraEnvironment;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.webui.package}/bin/garage-webui";
        EnvironmentFile = config.sops.templates."garage-webui.env".path;
        Restart = "always";
        RestartSec = "5s";
      };
    };

    # Firewall configuration
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.ports.rpc
        cfg.ports.s3
        cfg.ports.web
        cfg.ports.admin
        cfg.ports.k2v
      ]
      ++ lib.optionals cfg.webui.enable [
        cfg.ports.webui
      ];
    };
  };
}
