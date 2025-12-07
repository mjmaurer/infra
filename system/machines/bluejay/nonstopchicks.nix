{
  pkgs-latest,
  config,
  pkgs,
  lib,
  ...
}:

let
  nonstopchicksDomain = "nonstopchicks.com";
  hostPort = 4001; # Host port that nginx will proxy to
  containerPort = 3000; # Port the app listens on inside the container
  hostStateDir = "/var/lib/nonstopchicks"; # Persistent storage on the host

  ociBin =
    if (config.virtualisation.oci-containers.backend or "docker") == "podman" then
      "${pkgs.podman}/bin/podman"
    else
      "${pkgs.docker}/bin/docker";
  image = "ghcr.io/mjmaurer/nonstopchicks:sha-41a6846";
in
{
  # Ensure persistent storage exists
  systemd.tmpfiles.rules = [
    "d ${hostStateDir} 0755 root root - -"
    "d ${hostStateDir}/data 0775 1000 1000 - -"
  ];

  # Nonstop Chicks container
  virtualisation.oci-containers.containers.nonstopchicks =
    let
      containerWorkDir = "/app";
    in
    {
      image = image;
      pull = "always";
      autoRemoveOnStop = true;
      extraOptions = [ "--replace" ];

      # Bind only on loopback so it's reachable only via Caddy
      ports = [ "127.0.0.1:${toString hostPort}:${toString containerPort}" ];
      volumes = [
        "${hostStateDir}/data:/data"
      ];
      environmentFiles = [ config.sops.templates."nonstopchicks.env".path ];
      environment = {
        APP_WORKDIR = containerWorkDir;
        APP_HOST = nonstopchicksDomain;
        DEFAULT_USER_EMAIL = "mjmaurer777@gmail.com";
      };
    };

  services.caddy = {
    virtualHosts."${nonstopchicksDomain}".extraConfig = ''
      tls mjmaurer777@gmail.com {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
        resolvers 1.1.1.1 1.0.0.1
        propagation_timeout 10m
        propagation_delay 1m
      }
      encode zstd gzip
      request_body {
        max_size 30MB
      }
      reverse_proxy 127.0.0.1:${toString hostPort}
    '';
  };

  sops = {
    secrets = {
      youtubeApiKey = {
        sopsFile = ./secrets.yaml;
      };
    };

    templates = {
      "nonstopchicks.env" = {
        content = ''
          YOUTUBE_API_KEY=${config.sops.placeholder.youtubeApiKey}
        '';
      };
    };
  };

  systemd.services.nonstopchicks-rebuild-cache = {
    description = "Populate Nonstop Chicks cache (cache-build-env)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.templates."nonstopchicks.env".path;
      ExecStartPre = [
        "${pkgs.coreutils}/bin/install -d -m 0775 -o 1000 -g 1000 ${hostStateDir}/data"
        "${ociBin} pull ${image}"
      ];
      ExecStart = "${ociBin} run --rm -v ${hostStateDir}/data:/data --env YOUTUBE_API_KEY ${image} npm run rebuild-cache";
      TimeoutStartSec = "10m";
    };
  };

  systemd.timers.nonstopchicks-rebuild-cache = {
    wantedBy = [ "timers.target" ];
    partOf = [ "nonstopchicks-rebuild-cache.service" ];
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00 America/New_York";
      Persistent = true;
      RandomizedDelaySec = "10m";
    };
  };
}
