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
    hash = "sha256-4QbLyUaZ+5P+ZOotM6D3w275RDD/NaprzMS2orX7I6I=";
  };
in
{
  # Weekly image updates (see modules.virt.podmanAutoUpdate)
  modules.virt.podmanAutoUpdate.enable = true;

  virtualisation.oci-containers.containers."open-webui" = {
    image = "ghcr.io/open-webui/open-webui:main";

    pull = "always";
    labels."io.containers.autoupdate" = "registry";
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

  systemd.tmpfiles.rules = [
    "d ${hostStateDir} 0755 root root -"
  ];

  services.caddy = {
    enable = true;
    package = caddyPkg;
    virtualHosts."ai.maurer.exposed".extraConfig = ''
      tls mjmaurer777@gmail.com {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
        resolvers 1.1.1.1 1.0.0.1
        propagation_timeout -1
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
}
