{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ──────────────── Hard-coded parameters ────────────────
  hst = "bobby.place";

  # Upstream service ports (adjust to match your previous docker-compose .env)
  bobbyPort = 5000;
  automaticPort = 7860;
  rvcPort = 13337;
  plexWebPort = 32400;
  authextraPort = 3000;

in
{
  imports = [
    ../../modules/caddy/caddy.nix
  ];

  config = {
    # ------------------------------ Firewall ------------------------------
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    services.caddy.virtualHosts."${hst}".extraConfig = ''
      tls mjmaurer777@gmail.com {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
        resolvers 1.1.1.1 1.0.0.1
        propagation_timeout 10m
        propagation_delay 1m
      }
      encode zstd gzip
      redir https://google.com 301
    '';

    services.caddy.virtualHosts."plex.${hst}".extraConfig = ''
      tls mjmaurer777@gmail.com {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
        resolvers 1.1.1.1 1.0.0.1
        propagation_timeout 10m
        propagation_delay 1m
      }
      encode zstd gzip

      # Client body size (nginx client_max_body_size 100M)
      request_body {
        max_size 100MB
      }

      # Preserve the legacy /auth upstream endpoint
      # handle_path /auth* {
      #   reverse_proxy bobby:${toString bobbyPort} {
      #     header_up X-Original-URL {uri}
      #     header_up Content-Length ""
      #   }
      # }

      # Map nginx: error_page 403 = @error403 -> redirect to auth
      # handle_errors {
      #   @forbidden expression {http.error.status_code} == 403
      #   redir @forbidden https://${hst}/api/auth/redirect?next={http.request.host}{http.request.uri} 302
      # }

      # Reverse proxy to Plex with explicit headers and timeouts
      reverse_proxy willow:${toString plexWebPort} {
        # Match nginx proxy_set_header values
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
        header_up X-Forwarded-Port {server_port}
        header_up X-Scheme {scheme}

        # WebSocket-related (nginx proxy_http_version/upgrade)
        header_up Upgrade {>Upgrade}
        header_up Connection {>Connection}

        # Timeouts (nginx 120s)
        transport http {
          dial_timeout 120s
          read_timeout 120s
          write_timeout 120s
        }
      }
    '';
  };
}
