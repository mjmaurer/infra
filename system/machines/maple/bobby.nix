# Bobby (Discord bot + bobby.place portal), as two instances using maple's Postgres:
#
#   bobby       real bot    https://bobby.place       ghcr.io/mjmaurer/bobby:prod  port 8000
#   bobby-test  test bot    https://test.bobby.place  ghcr.io/mjmaurer/bobby:dev   port 8002
#
# bobby-bot's CI publishes :dev on every push to dev; its "Promote to prod" workflow retags a
# tested image as :prod. modules.containerUpdater restarts an instance within minutes of its
# tag moving, so the test bot follows every push and the real bot follows promotions.
#
# The GPU voice service runs on ash (system/machines/ash/bobby-rvc.nix); dove's Caddy reaches
# these instances over Tailscale. Each instance has its own database and user, and neither can
# connect to the other's database.
#
# Before deploying, add these keys to ./secrets.yaml (`sops system/machines/maple/secrets.yaml`).
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
{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "bobby.place";
  stateDir = "/var/lib/bobby";
  registry = "ghcr.io/mjmaurer";
  pgPort = config.modules.postgresql.port;
  psql = "${config.services.postgresql.package}/bin/psql";
  pgDump = "${config.services.postgresql.package}/bin/pg_dump";

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

  secret = name: config.sops.placeholder.${name};

  mkInstance = name: inst: {
    image = "${registry}/bobby:${inst.imageTag}";
    pull = "always";
    login = {
      registry = "ghcr.io";
      username = "mjmaurer";
      passwordFile = config.sops.secrets.bobbyGhcrToken.path;
    };
    autoRemoveOnStop = true;
    # Host networking: reaches Postgres on 127.0.0.1 and listens on inst.port, which dove
    # reaches over Tailscale (tailscale0 is a trusted interface).
    extraOptions = [
      "--replace"
      "--network=host"
    ];
    volumes = [ "${stateDir}/${name}/uploads:/app/uploads" ];
    environmentFiles = [ config.sops.templates."${name}.env".path ];
    environment = {
      ENV_NAME = "production";
      HOST = domain;
      PUBLIC_URL = inst.publicUrl;
      BOBBY_PORT = toString inst.port;
      BOT_COMMAND_PREFIX = inst.commandPrefix;
      SESSION_COOKIE_NAME = inst.sessionCookie;
      RVC_URL = "http://ash:8001";
      RADARR_URL = "http://willow:7878";
    };
  };

  mkEnvTemplate =
    name: inst:
    let
      p = inst.secretPrefix;
    in
    {
      content = ''
        SECRET_KEY=${secret "${p}SecretKey"}
        DATABASE_URL=postgresql+asyncpg://${inst.database}:${secret "${p}PostgresPassword"}@127.0.0.1:${toString pgPort}/${inst.database}
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

  databases = map (inst: inst.database) (lib.attrValues instances);
in
{
  imports = [ ../../modules/container-updater.nix ];

  # Databases and users (one each per instance, user owns its database).
  modules.postgresql = {
    ensureDatabases = databases;
    ensureUsers = map (db: {
      name = db;
      ensureDBOwnership = true;
    }) databases;
  };

  # Sets each user's password from sops and stops users connecting to other databases.
  # Idempotent; reruns on every boot/deploy. Statement logging is off for this session so the
  # passwords don't land in Postgres's log (maple logs all statements).
  systemd.services.bobby-db-setup = {
    description = "Set Bobby's Postgres passwords and database access";
    after = [ "postgresql-setup.service" ];
    requires = [ "postgresql-setup.service" ];
    before = map (name: "podman-${name}.service") (lib.attrNames instances);
    requiredBy = map (name: "podman-${name}.service") (lib.attrNames instances);
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };
    script = ''
      ${psql} -v ON_ERROR_STOP=1 -d postgres \
        ${
          lib.concatMapStringsSep " " (
            inst:
            ''-v ${inst.database}="$(cat ${config.sops.secrets."${inst.secretPrefix}PostgresPassword".path})"''
          ) (lib.attrValues instances)
        } <<'SQL'
      SET log_statement = 'none';
      ${lib.concatMapStrings (db: ''
        ALTER ROLE ${db} WITH LOGIN PASSWORD :'${db}';
        REVOKE CONNECT ON DATABASE ${db} FROM PUBLIC;
        GRANT CONNECT ON DATABASE ${db} TO ${db};
      '') databases}
      SQL
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 root root - -"
    "d ${stateDir}/backups 0700 postgres postgres - -"
  ]
  ++ lib.mapAttrsToList (name: _: "d ${stateDir}/${name}/uploads 0755 1000 1000 - -") instances;

  virtualisation.oci-containers.containers = lib.mapAttrs mkInstance instances;

  modules.containerUpdater.containers = lib.attrNames instances;

  # Nightly dump of both databases into ${stateDir}/backups (14 days kept).
  systemd.services.bobby-db-backup = {
    description = "Dump Bobby's Postgres databases";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };
    script =
      lib.concatMapStrings (db: ''
        ${pgDump} -Fc ${db} > ${stateDir}/backups/${db}-$(date +%F).dump
      '') databases
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
        })
      # Read by bobby-db-setup, which runs as postgres.
      //
        lib.genAttrs (map (inst: "${inst.secretPrefix}PostgresPassword") (lib.attrValues instances))
          (_: {
            sopsFile = ./secrets.yaml;
            owner = "postgres";
          });

    templates = lib.mapAttrs' (
      name: inst: lib.nameValuePair "${name}.env" (mkEnvTemplate name inst)
    ) instances;
  };
}
