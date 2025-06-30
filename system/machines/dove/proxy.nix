{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ──────────────── Hard-coded parameters ────────────────
  host = "example.com"; # ← change to your apex domain

  # Upstream service ports (adjust to match your previous docker-compose .env)
  bobbyPort = 5000;
  automaticPort = 7860;
  rvcPort = 13337;
  plexWebPort = 32400;
  jellyfinWebPort = 8096;
  authextraPort = 3000;

  # Convenience to avoid repetition in virtualHosts that share the same SSL cert
  acmeCertName = host;

in
{
  # ------------------------------ Firewall ------------------------------
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # ------------------------------  ACME  -------------------------------
  security.acme = {
    acceptTerms = true;
    defaults.email = "mjmaurer777@gmail.com";

    certs."${acmeCertName}" = {
      webroot = "/var/www/acme"; # matches the /.well-known location used below
      extraDomainNames = [
        "jellyfin.${host}"
        "invites.${host}"
        "plex.${host}"
        "automatic1111.${host}"
        "rvc.${host}"
      ];
    };
  };

  # Ensure the ACME web-root directory exists at boot
  systemd.tmpfiles.rules = [
    "d /var/www/acme 0755 nginx nginx - -"
  ];

  # ------------------------------  NGINX  ------------------------------
  services.nginx = {
    enable = true;
    package = pkgs.nginxMainline;

    # Pull in sensible defaults from the upstream NixOS module
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    # Global http-context directives copied from the original templates
    commonHttpConfig = ''
      client_max_body_size 80M;

      upstream bobby-api {
        server bobby:${toString bobbyPort};
      }

      upstream multiauth {
        server 127.0.2.1:8000 max_fails=0 weight=5;
        server 127.0.2.1:8001 max_fails=0;
      }
    '';

    # -------------------------- Virtual hosts --------------------------
    virtualHosts = {
      # ── 1) HTTP → HTTPS redirects (root + wildcard) ──────────────────
      "redirect-root" = {
        serverName = host;
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];
        locations."/.well-known/acme-challenge/".root = "/var/www/acme";
        extraConfig = ''return 301 https://$host$request_uri;'';
      };

      "redirect-wildcard" = {
        serverName = "*.${host}";
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];
        locations."/.well-known/acme-challenge/".root = "/var/www/acme";
        extraConfig = ''return 301 https://$host$request_uri;'';
      };

      # ── 2) Internal helper listeners used by multiauth ───────────────
      "auth-extra-8000" = {
        serverName = "_";
        listen = [
          {
            addr = "127.0.2.1";
            port = 8000;
          }
        ];
        locations."/".extraConfig = ''
          proxy_pass http://authextra:${toString authextraPort}/jellyauth/;
          proxy_pass_request_body off;
          proxy_set_header        Content-Length "";
          proxy_set_header        X-Original-URI $request_uri;
        '';
      };

      "auth-extra-8001" = {
        inherit (config.services.nginx.virtualHosts."auth-extra-8000") serverName;
        listen = [
          {
            addr = "127.0.0.1";
            port = 8001;
          }
        ];
      };

      # ── 3) Apex domain → Bobby API ───────────────────────────────────
      "${host}" = {
        useACMEHost = acmeCertName;
        forceSSL = true;
        locations."/".proxyPass = "http://bobby-api";
      };

      # ── 4) automatic1111.${host} ─────────────────────────────────────
      "automatic1111.${host}" = {
        useACMEHost = acmeCertName;
        forceSSL = true;

        extraConfig = ''auth_request /auth;'';

        locations."/" = {
          proxyPass = "http://bobby:${toString automaticPort}/";
          extraConfig = ''error_page 403 = @error403;'';
        };

        # Forward auth probe to Bobby
        locations."/auth".extraConfig = ''
          proxy_pass http://bobby:${toString bobbyPort}/api/user/;
          proxy_pass_request_body off;
          proxy_set_header Content-Length "";
          proxy_set_header X-Original-URL $request_uri;
          proxy_next_upstream error http_503 non_idempotent;
        '';

        # 302 redirect on 403s
        extraConfig = ''
          location @error403 {
            return 302 https://${host}/api/auth/redirect?next=$http_host$request_uri;
          }
        '';
      };

      # ── 5) rvc.${host} ───────────────────────────────────────────────
      "rvc.${host}" = {
        useACMEHost = acmeCertName;
        forceSSL = true;
        extraConfig = ''auth_request /auth;'';
        locations."/" = {
          proxyPass = "http://bobby:${toString rvcPort}/";
          extraConfig = ''error_page 403 = @error403;'';
        };
        extraConfig = ''
          location @error403 {
            return 302 https://${host}/api/auth/redirect?next=$http_host$request_uri;
          }
        '';
      };

      # ── 6) plex.${host} (adds special Plex headers) ──────────────────
      "plex.${host}" = {
        useACMEHost = acmeCertName;
        forceSSL = true;

        # Web-socket helpers (was in subdomain.include)
        extraConfig = ''
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
        '';

        locations."/".extraConfig = ''
          proxy_pass   http://earth:${toString plexWebPort}/;
          error_page   403 = @error403;

          proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
          proxy_set_header X-Plex-Device          $http_x_plex_device;
          proxy_set_header X-Plex-Device-Name     $http_x_plex_device_name;
          proxy_set_header X-Plex-Platform        $http_x_plex_platform;
          proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
          proxy_set_header X-Plex-Product         $http_x_plex_product;
          proxy_set_header X-Plex-Token           $http_x_plex_token;
          proxy_set_header X-Plex-Version         $http_x_plex_version;
          proxy_set_header X-Plex-Nocache         $http_x_plex_nocache;
          proxy_set_header X-Plex-Provides        $http_x_plex_provides;
          proxy_set_header X-Plex-Device-Vendor   $http_x_plex_device_vendor;
          proxy_set_header X-Plex-Model           $http_x_plex_model;
        '';
      };

      # ── 7) invites.${host} ───────────────────────────────────────────
      "invites.${host}" = {
        useACMEHost = acmeCertName;
        forceSSL = true;
        extraConfig = ''auth_request /auth;'';
        locations."/" = {
          proxyPass = "http://earth:5690/";
          extraConfig = ''error_page 403 = @error403;'';
        };
      };

      # ── 8) jellyfin.${host} ──────────────────────────────────────────
      "jellyfin.${host}" = {
        useACMEHost = acmeCertName;
        forceSSL = true;

        extraConfig = ''
          auth_request /auth;
          add_header X-Frame-Options "SAMEORIGIN";
          add_header X-XSS-Protection "0";
          add_header X-Content-Type-Options "nosniff";
          add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;
        '';

        locations."/" = {
          proxyPass = "http://earth:${toString jellyfinWebPort}/";
          extraConfig = ''proxy_buffering off;'';
        };

        locations."/Users".proxyPass = "http://earth:${toString jellyfinWebPort}";

        # Pretty URL for /web ↔ /web/index.html
        locations."= /web/".proxyPass = "http://earth:${toString jellyfinWebPort}/web/index.html";

        # Internal jellyauth stub
        locations."/jellyauth".extraConfig = ''
          internal;
          proxy_pass http://authextra:${toString authextraPort}/jellyauth/;
          proxy_pass_request_body off;
          proxy_set_header Content-Length "";
        '';
      };
    };
  };
}
