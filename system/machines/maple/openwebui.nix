{
  pkgs-latest,
  config,
  lib,
  ...
}:
let
  hostStateDir = "/var/lib/openwebui";
  containerStateDir = "/state";

  caddyPkg = pkgs-latest.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
    hash = "sha256-2YE3o6ba1BplLDaDilszpvt+KuHBW7MngosRWet2LGw=";
  };
in
{
  virtualisation.oci-containers.containers."open-webui" = {
    image = "ghcr.io/open-webui/open-webui:main";

    pull = "always";
    autoStart = true;
    autoRemoveOnStop = true;
    extraOptions = [ "--replace" ];

    ports = [ "127.0.0.1:8181:8181/tcp" ];
    volumes = [
      "${hostStateDir}:/app/backend/data"
    ];
    # environmentFiles = [ config.sops.templates."openwebui.env".path ];
    environment = {
      PORT = "8181";

      WEBUI_URL = "http://localhost:8181";

      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };
  };

  services.caddy = {
    enable = true;
    package = caddyPkg;
    virtualHosts."ai.maurer.exposed".extraConfig = ''
      tls mjmaurer777@gmail.com {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        resolvers 1.1.1.1
      }
      reverse_proxy 127.0.0.1:8181
    '';
  };

  sops.templates."maple-caddy.env" = {
    content = ''
      CLOUDFLARE_API_TOKEN=${config.sops.placeholder.cloudflareDnsApiToken}
    '';
    mode = "0400";
    owner = "root";
    group = "root";
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.sops.templates."maple-caddy.env".path
  ];

  systemd.tmpfiles.rules = [
    "d ${hostStateDir} 0755 root root -"
  ];
}
