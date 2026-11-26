{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ──────────────── Hard-coded parameters ────────────────
  hst = "bobby.place";

  # Bobby runs on ash (system/machines/ash/bobby.nix), reached over Tailscale.
  bobbyUpstream = "ash:8000";
  plexWebPort = 32400;

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

    # `import bobby_auth` in a site block = only logged-in Bobcorp Discord members get through.
    # Bobby's /api/user/ answers 200 (logged in) or 401; 401s go to the Discord login and come
    # back to the original URL. Browser-only: native apps (e.g. Plex on a TV) can't log in.
    services.caddy.extraConfig = ''
      (bobby_auth) {
        forward_auth ${bobbyUpstream} {
          uri /api/user/
          @unauthorized status 401
          handle_response @unauthorized {
            redir https://${hst}/api/auth/redirect?next={http.request.host}{http.request.uri} 302
          }
        }
      }
    '';

    services.caddy.virtualHosts."${hst}".extraConfig = ''
      tls mjmaurer777@gmail.com {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
        resolvers 1.1.1.1 1.0.0.1
        propagation_timeout 10m
        propagation_delay 1m
      }
      encode zstd gzip
      request_body {
        max_size 100MB
      }
      reverse_proxy ${bobbyUpstream}
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

      # Not gated by Bobby login: native Plex apps can't use the browser session.
      # Uncomment to require it for every request (breaks TV/mobile apps):
      # import bobby_auth

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
