{
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
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

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
  ];

  # Nonstop Chicks container
  virtualisation.oci-containers.containers.nonstopchicks =
    let
      containerWorkDir = "/app";
    in
    {
      image = "ghcr.io/mjmaurer/nonstopchicks:latest";
      pull = "always";
      autoRemoveOnStop = true;
      extraOptions = [ "--replace" ];

      # Bind only on loopback so it's reachable only via nginx
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

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    virtualHosts."${nonstopchicksDomain}" = {
      enableACME = true;
      forceSSL = true;
      extraConfig = ''
        client_max_body_size 30M;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString hostPort}";
      };
    };
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
}
