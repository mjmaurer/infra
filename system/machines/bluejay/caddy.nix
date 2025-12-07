{ pkgs-latest, config, ... }:
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy =
    let
      caddyPkg = pkgs-latest.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
        hash = "sha256-2YE3o6ba1BplLDaDilszpvt+KuHBW7MngosRWet2LGw=";
      };
    in
    {
      enable = true;
      package = caddyPkg;
    };

  templates = {
    "bluejay-caddy.env" = {
      content = ''
        CLOUDFLARE_API_TOKEN=${config.sops.placeholder.cloudflareDnsApiToken}
      '';
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.sops.templates."bluejay-caddy.env".path
  ];
}
