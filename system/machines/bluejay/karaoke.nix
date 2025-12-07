{
  pkgs-latest,
  config,
  pkgs,
  lib,
  ...
}:

let
  karaokeDomain = "okdokkaraoke.com";
  hostPort = 4000; # Host port that nginx will proxy to
  containerPort = 8000; # Port the app listens on inside the container
  hostStateDir = "/var/lib/karaoke"; # Persistent storage on the host
in
{
  # Ensure persistent storage exists
  systemd.tmpfiles.rules = [
    "d ${hostStateDir} 0755 root root - -"
    "d ${hostStateDir}/static 0755 root root - -"
    "d ${hostStateDir}/media 0755 root root - -"
    "d ${hostStateDir}/data 0755 root root - -"
  ];

  # Karaoke container
  virtualisation.oci-containers.containers.karaoke =
    let
      containerWorkDir = "/app";
    in
    {
      image = "ghcr.io/mjmaurer/okie-dokie-karaoke:latest";
      pull = "always";
      autoRemoveOnStop = true;
      extraOptions = [ "--replace" ];

      # Bind only on loopback so it's reachable only via nginx
      ports = [ "127.0.0.1:${toString hostPort}:${toString containerPort}" ];
      volumes = [
        "${hostStateDir}/media:${containerWorkDir}/media"
        "${hostStateDir}/static:${containerWorkDir}/static"
        "${hostStateDir}/data:${containerWorkDir}/data"
      ];
      environmentFiles = [ config.sops.templates."karaoke.env".path ];
      environment = {
        APP_WORKDIR = containerWorkDir;
        APP_HOST = karaokeDomain;
        DJANGO_SETTINGS_MODULE = "openkjui.settings.production";
        DEFAULT_USER_EMAIL = "mjmaurer777@gmail.com";
      };
    };

  services.caddy = {
    virtualHosts."${karaokeDomain}".extraConfig = ''
      tls mjmaurer777@gmail.com {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
        resolvers 1.1.1.1 1.0.0.1
        propagation_timeout -1
      }
      encode zstd gzip
      request_body {
        max_size 30MB
      }
      handle_path /static/* {
        root * ${hostStateDir}/static
        file_server browse
      }
      handle_path /media/* {
        root * ${hostStateDir}/media
        file_server browse
      }
      reverse_proxy 127.0.0.1:${toString hostPort}
    '';
  };

  sops = {
    secrets = {
      karaokeUserPassword = {
        sopsFile = ./secrets.yaml;
      };
      karaokeSecretKey = {
        sopsFile = ./secrets.yaml;
      };
    };

    templates = {
      "karaoke.env" = {
        content = ''
          DEFAULT_USER_PASSWORD=${config.sops.placeholder.karaokeUserPassword}
          DJANGO_SECRET_KEY=${config.sops.placeholder.karaokeSecretKey}
        '';
      };
    };
  };
}
