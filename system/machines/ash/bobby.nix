# Bobby (Discord bot + bobby.place portal) and its GPU voice service.
# Source and images: https://github.com/mjmaurer/bobby-bot (ghcr.io/mjmaurer/bobby{,-rvc}).
# dove's Caddy reaches the app over Tailscale at ash:${bobbyPort}.
#
# Before deploying, add these keys to ./secrets.yaml (`sops system/machines/ash/secrets.yaml`):
#   bobbySecretKey             long random string (session signing)
#   bobbyPostgresPassword      any random string
#   bobbyDiscordClientId       Discord application (OAuth2) client ID
#   bobbyDiscordClientSecret   Discord application (OAuth2) client secret
#   bobbyDiscordBotToken       Discord bot token
#   bobbyDiscordGuildId        server whose members may log in
#   bobbyRadarrApiKey          Radarr API key (willow)
#   bobbyGhcrToken             GitHub token with read:packages (bobby-bot's images are private)
#
# Voices: copy trained RVC voices to ${stateDir}/voices/<name>/{*.pth,*.index}.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "bobby.place";
  bobbyPort = 8000;
  rvcPort = 8001;
  stateDir = "/var/lib/bobby";
  # Branch tag published by bobby-bot's CI. Switch to "main" once dev is merged.
  imageTag = "dev";
  network = "bobby";

  common = {
    pull = "always";
    login = {
      registry = "ghcr.io";
      username = "mjmaurer";
      passwordFile = config.sops.secrets.bobbyGhcrToken.path;
    };
    autoRemoveOnStop = true;
    extraOptions = [
      "--replace"
      "--network=${network}"
    ];
  };
in
{
  # The three containers talk over a private Docker network by container name.
  systemd.services.docker-network-bobby = {
    description = "Docker network for Bobby";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    before = [
      "docker-bobby.service"
      "docker-bobby-rvc.service"
      "docker-bobby-postgres.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect ${network} >/dev/null 2>&1 \
        || ${pkgs.docker}/bin/docker network create ${network}
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 root root - -"
    "d ${stateDir}/postgres 0700 999 999 - -"
    "d ${stateDir}/uploads 0755 1000 1000 - -"
    "d ${stateDir}/voices 0755 root root - -"
    "d ${stateDir}/backups 0700 999 999 - -"
  ];

  # Docker needs CDI enabled for --device=nvidia.com/gpu=all (see modules/graphics/nvidia.nix).
  virtualisation.docker.daemon.settings.features.cdi = true;

  virtualisation.oci-containers.containers = {
    bobby-postgres = lib.mkMerge [
      common
      {
        image = "docker.io/library/postgres:17";
        environmentFiles = [ config.sops.templates."bobby-postgres.env".path ];
        environment = {
          POSTGRES_USER = "bobby";
          POSTGRES_DB = "bobby";
        };
        volumes = [ "${stateDir}/postgres:/var/lib/postgresql/data" ];
      }
    ];

    bobby-rvc = lib.mkMerge [
      common
      {
        image = "ghcr.io/mjmaurer/bobby-rvc:${imageTag}";
        volumes = [ "${stateDir}/voices:/voices:ro" ];
        extraOptions = [ "--device=nvidia.com/gpu=all" ];
      }
    ];

    bobby = lib.mkMerge [
      common
      {
        image = "ghcr.io/mjmaurer/bobby:${imageTag}";
        dependsOn = [
          "bobby-postgres"
          "bobby-rvc"
        ];
        # Reachable from dove over Tailscale (tailscale0 is a trusted interface).
        ports = [ "${toString bobbyPort}:${toString bobbyPort}" ];
        volumes = [ "${stateDir}/uploads:/app/uploads" ];
        environmentFiles = [ config.sops.templates."bobby.env".path ];
        environment = {
          ENV_NAME = "production";
          HOST = domain;
          PUBLIC_URL = "https://${domain}";
          BOBBY_PORT = toString bobbyPort;
          RVC_URL = "http://bobby-rvc:${toString rvcPort}";
          RADARR_URL = "http://willow:7878";
        };
      }
    ];
  };

  # Nightly database dump into ${stateDir}/backups (14 days kept).
  systemd.services.bobby-db-backup = {
    description = "Dump Bobby's Postgres database";
    after = [ "docker-bobby-postgres.service" ];
    requires = [ "docker-bobby-postgres.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.docker}/bin/docker exec bobby-postgres pg_dump -U bobby -Fc bobby \
        > ${stateDir}/backups/bobby-$(date +%F).dump
      ${pkgs.findutils}/bin/find ${stateDir}/backups -name 'bobby-*.dump' -mtime +14 -delete
    '';
  };
  systemd.timers.bobby-db-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:30:00";
      Persistent = true;
    };
  };

  sops = {
    secrets =
      lib.genAttrs
        [
          "bobbySecretKey"
          "bobbyPostgresPassword"
          "bobbyDiscordClientId"
          "bobbyDiscordClientSecret"
          "bobbyDiscordBotToken"
          "bobbyDiscordGuildId"
          "bobbyRadarrApiKey"
          "bobbyGhcrToken"
        ]
        (_: {
          sopsFile = ./secrets.yaml;
        });

    templates = {
      "bobby-postgres.env".content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder.bobbyPostgresPassword}
      '';
      "bobby.env".content = ''
        SECRET_KEY=${config.sops.placeholder.bobbySecretKey}
        DATABASE_URL=postgresql+asyncpg://bobby:${config.sops.placeholder.bobbyPostgresPassword}@bobby-postgres:5432/bobby
        DISCORD_CLIENT_ID=${config.sops.placeholder.bobbyDiscordClientId}
        DISCORD_CLIENT_SECRET=${config.sops.placeholder.bobbyDiscordClientSecret}
        DISCORD_BOT_TOKEN=${config.sops.placeholder.bobbyDiscordBotToken}
        DISCORD_GUILD_ID=${config.sops.placeholder.bobbyDiscordGuildId}
        RADARR_API_KEY=${config.sops.placeholder.bobbyRadarrApiKey}
      '';
    };
  };
}
