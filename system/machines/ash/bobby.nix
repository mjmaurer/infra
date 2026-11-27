# Bobby (Discord bot + bobby.place portal) and its GPU voice service, as two instances:
#
#   bobby       real bot    https://bobby.place       ghcr.io/mjmaurer/bobby:prod  port 8000
#   bobby-test  test bot    https://test.bobby.place  ghcr.io/mjmaurer/bobby:dev   port 8002
#
# bobby-bot's CI publishes :dev on every push to dev; its "Promote to prod" workflow retags a
# tested image as :prod. A timer here restarts any container whose tag points at a new image,
# so the test bot follows every push and the real bot follows promotions.
#
# Shared: one voice service (bobby-rvc, follows :prod) and one Postgres container with a
# database and user per instance. dove's Caddy reaches the instances over Tailscale.
#
# Before deploying, add these keys to ./secrets.yaml (`sops system/machines/ash/secrets.yaml`).
# Per instance (prefix `bobby` for the real bot, `bobbyTest` for the test bot):
#   <prefix>SecretKey             long random string (session signing)
#   <prefix>PostgresPassword      any random string
#   <prefix>DiscordClientId       Discord application (OAuth2) client ID
#   <prefix>DiscordClientSecret   Discord application (OAuth2) client secret
#   <prefix>DiscordBotToken       Discord bot token
#   <prefix>DiscordGuildId        server whose members may log in
# Shared:
#   bobbyRadarrApiKey             Radarr API key (willow)
#   bobbyGhcrToken                GitHub token with read:packages (bobby-bot's images are private)
#
# Voices: copy trained RVC voices to /var/lib/bobby/voices/<name>/{*.pth,*.index}.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "bobby.place";
  stateDir = "/var/lib/bobby";
  network = "bobby";
  registry = "ghcr.io/mjmaurer";
  rvcPort = 8001;
  docker = "${pkgs.docker}/bin/docker";

  instances = {
    bobby = {
      imageTag = "prod";
      publicUrl = "https://${domain}";
      port = 8000;
      database = "bobby";
      secretPrefix = "bobby";
      commandPrefix = "";
      sessionCookie = "bobby_session";
    };
    bobby-test = {
      imageTag = "dev";
      publicUrl = "https://test.${domain}";
      port = 8002;
      database = "bobby_test";
      secretPrefix = "bobbyTest";
      commandPrefix = "test-";
      sessionCookie = "bobby_test_session";
    };
  };

  # The real bot's user is the Postgres superuser; the test bot gets an ordinary user that can
  # only reach its own database (created by bobby-db-setup).
  superuser = instances.bobby.database;
  testDatabase = instances.bobby-test.database;

  secret = name: config.sops.placeholder.${name};

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

  mkInstance =
    name: inst:
    lib.mkMerge [
      common
      {
        image = "${registry}/bobby:${inst.imageTag}";
        dependsOn = [
          "bobby-postgres"
          "bobby-rvc"
        ];
        # Reachable from dove over Tailscale (tailscale0 is a trusted interface).
        ports = [ "${toString inst.port}:${toString inst.port}" ];
        volumes = [ "${stateDir}/${name}/uploads:/app/uploads" ];
        environmentFiles = [ config.sops.templates."${name}.env".path ];
        environment = {
          ENV_NAME = "production";
          HOST = domain;
          PUBLIC_URL = inst.publicUrl;
          BOBBY_PORT = toString inst.port;
          BOT_COMMAND_PREFIX = inst.commandPrefix;
          SESSION_COOKIE_NAME = inst.sessionCookie;
          RVC_URL = "http://bobby-rvc:${toString rvcPort}";
          RADARR_URL = "http://willow:7878";
        };
      }
    ];

  mkEnvTemplate =
    name: inst:
    let
      p = inst.secretPrefix;
    in
    {
      content = ''
        SECRET_KEY=${secret "${p}SecretKey"}
        DATABASE_URL=postgresql+asyncpg://${inst.database}:${secret "${p}PostgresPassword"}@bobby-postgres:5432/${inst.database}
        DISCORD_CLIENT_ID=${secret "${p}DiscordClientId"}
        DISCORD_CLIENT_SECRET=${secret "${p}DiscordClientSecret"}
        DISCORD_BOT_TOKEN=${secret "${p}DiscordBotToken"}
        DISCORD_GUILD_ID=${secret "${p}DiscordGuildId"}
        RADARR_API_KEY=${secret "bobbyRadarrApiKey"}
      '';
    };

  instanceSecretNames = lib.concatMap (
    inst:
    map (suffix: "${inst.secretPrefix}${suffix}") [
      "SecretKey"
      "PostgresPassword"
      "DiscordClientId"
      "DiscordClientSecret"
      "DiscordBotToken"
      "DiscordGuildId"
    ]
  ) (lib.attrValues instances);

  # Containers the update timer checks for newer images.
  updatable = [ "bobby-rvc" ] ++ lib.attrNames instances;
in
{
  # All containers talk over a private Docker network by container name.
  systemd.services.docker-network-bobby = {
    description = "Docker network for Bobby";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    before = map (c: "docker-${c}.service") ([ "bobby-postgres" ] ++ updatable);
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${docker} network inspect ${network} >/dev/null 2>&1 || ${docker} network create ${network}
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 root root - -"
    "d ${stateDir}/postgres 0700 999 999 - -"
    "d ${stateDir}/voices 0755 root root - -"
    "d ${stateDir}/backups 0700 root root - -"
  ]
  ++ lib.mapAttrsToList (name: _: "d ${stateDir}/${name}/uploads 0755 1000 1000 - -") instances;

  # Docker needs CDI enabled for --device=nvidia.com/gpu=all (see modules/graphics/nvidia.nix).
  virtualisation.docker.daemon.settings.features.cdi = true;

  virtualisation.oci-containers.containers = {
    bobby-postgres = lib.mkMerge [
      common
      {
        image = "docker.io/library/postgres:17";
        environmentFiles = [ config.sops.templates."bobby-postgres.env".path ];
        environment = {
          POSTGRES_USER = superuser;
          POSTGRES_DB = instances.bobby.database;
        };
        volumes = [ "${stateDir}/postgres:/var/lib/postgresql/data" ];
      }
    ];

    bobby-rvc = lib.mkMerge [
      common
      {
        image = "${registry}/bobby-rvc:prod";
        volumes = [ "${stateDir}/voices:/voices:ro" ];
        extraOptions = [ "--device=nvidia.com/gpu=all" ];
      }
    ];
  }
  // lib.mapAttrs mkInstance instances;

  # Creates the test bot's user and database (idempotent; also resets its password from sops).
  systemd.services.bobby-db-setup = {
    description = "Create Bobby's test database and user";
    after = [ "docker-bobby-postgres.service" ];
    requires = [ "docker-bobby-postgres.service" ];
    before = [ "docker-bobby-test.service" ];
    requiredBy = [ "docker-bobby-test.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for _ in $(seq 60); do
        ${docker} exec bobby-postgres pg_isready -U ${superuser} -q && break
        sleep 1
      done
      ${docker} exec -i bobby-postgres psql -v ON_ERROR_STOP=1 -U ${superuser} -d postgres \
        -v pw="$(cat ${config.sops.secrets.bobbyTestPostgresPassword.path})" <<'SQL'
      SELECT format('CREATE ROLE ${testDatabase} LOGIN PASSWORD %L', :'pw')
        WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${testDatabase}') \gexec
      ALTER ROLE ${testDatabase} PASSWORD :'pw';
      SELECT 'CREATE DATABASE ${testDatabase} OWNER ${testDatabase}'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${testDatabase}') \gexec
      REVOKE CONNECT ON DATABASE ${instances.bobby.database} FROM PUBLIC;
      REVOKE CONNECT ON DATABASE ${testDatabase} FROM PUBLIC;
      GRANT CONNECT ON DATABASE ${testDatabase} TO ${testDatabase};
      SQL
    '';
  };

  # Every 5 minutes: pull each container's tag and restart it if the tag moved. Restarting
  # runs the app's database migrations. Failed pulls are skipped until the next run.
  systemd.services.bobby-update = {
    description = "Restart Bobby containers whose image tag moved";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for container in ${lib.concatStringsSep " " updatable}; do
        image=$(${docker} inspect -f '{{.Config.Image}}' "$container" 2>/dev/null) || continue
        ${docker} pull -q "$image" >/dev/null || { echo "pull failed: $image"; continue; }
        latest=$(${docker} image inspect -f '{{.Id}}' "$image")
        running=$(${docker} inspect -f '{{.Image}}' "$container")
        if [ "$latest" != "$running" ]; then
          echo "$container: new image for $image, restarting"
          systemctl restart "docker-$container.service"
        fi
      done
    '';
  };
  systemd.timers.bobby-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
    };
  };

  # Nightly dump of both databases into ${stateDir}/backups (14 days kept).
  systemd.services.bobby-db-backup = {
    description = "Dump Bobby's Postgres databases";
    after = [ "docker-bobby-postgres.service" ];
    requires = [ "docker-bobby-postgres.service" ];
    serviceConfig.Type = "oneshot";
    script =
      lib.concatMapStrings (inst: ''
        ${docker} exec bobby-postgres pg_dump -U ${superuser} -Fc ${inst.database} \
          > ${stateDir}/backups/${inst.database}-$(date +%F).dump
      '') (lib.attrValues instances)
      + ''
        ${pkgs.findutils}/bin/find ${stateDir}/backups -name '*.dump' -mtime +14 -delete
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
        (
          instanceSecretNames
          ++ [
            "bobbyRadarrApiKey"
            "bobbyGhcrToken"
          ]
        )
        (_: {
          sopsFile = ./secrets.yaml;
        });

    templates = {
      "bobby-postgres.env".content = ''
        POSTGRES_PASSWORD=${secret "bobbyPostgresPassword"}
      '';
    }
    // lib.mapAttrs' (name: inst: lib.nameValuePair "${name}.env" (mkEnvTemplate name inst)) instances;
  };
}
