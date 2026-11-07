{
  config,
  lib,
  pkgs,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.caddy;
in
{
  options.modules.caddy = { };

  config = {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services.caddy =
      let
        caddyPkg = pkgs-latest.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
          hash = "sha256-4QbLyUaZ+5P+ZOotM6D3w275RDD/NaprzMS2orX7I6I=";
        };
      in
      {
        enable = true;
        package = caddyPkg;
      };

    sops.templates = {
      "caddy-dns.env" = {
        content = ''
          CLOUDFLARE_API_TOKEN=${config.sops.placeholder.cloudflareDnsApiToken}
        '';
        mode = "0400";
        owner = "root";
        group = "root";
      };
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile = [
      config.sops.templates."caddy-dns.env".path
    ];
  };
}
