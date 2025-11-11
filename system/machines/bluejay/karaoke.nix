{
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
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # ACME for automatic certs
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "mjmaurer777@gmail.com";
      group = "nginx";
    };
  };

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

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    virtualHosts."${karaokeDomain}" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        client_max_body_size 30M;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString hostPort}";
      };
      locations."/static/".extraConfig = ''
        autoindex on;
        alias ${hostStateDir}/static/;
      '';
      locations."/media/".extraConfig = ''
        autoindex on;
        alias ${hostStateDir}/media/;
      '';
    };
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
