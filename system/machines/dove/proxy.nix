{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Hardcoded values from docker-compose and .env
  host = "bobby.place";
  bobbyPort = "8000";
  automaticPort = "7860";
  rvcPort = "7865";
  plexWebPort = "32400";
  jellyfinWebPort = "8096";
  authExtraPort = "3000";
  invitesPort = "5690";

  bobbyHost = "bobby";
  earthHost = "earth";
  authExtraHost = "authextra";

  # Common locations for subdomains requiring auth
  authLocations = {
    # The main auth endpoint that checks the user's session
    "/auth" = {
      proxyPass = "http://${bobbyHost}:${bobbyPort}/api/user/";
      proxyPassRequestBody = false;
      proxyHeaders."Content-Length" = "";
      proxyHeaders."X-Original-URL" = "$request_uri";
      extraConfig = "proxy_next_upstream error http_503 non_idempotent;";
    };
    # Redirect to login page on auth failure
    "@error403" = {
      extraConfig = "return 302 https://${host}/api/auth/redirect?next=$http_host$request_uri;";
    };
  };

  # Common settings for subdomains from subdomain.include.template
  subdomainSettings = {
    # Websocket support
    proxyWebsockets = true;
    # Timeouts
    proxyConnectTimeout = "120s";
    proxySendTimeout = "120s";
    proxyReadTimeout = "120s";
    # Buffers
    proxyBuffers = "4 256k";
    proxyBufferSize = "128k";
    proxyBusyBuffersSize = "256k";
    # Body size
    clientMaxBodySize = "100M";
    # Auth cookie handling
    extraConfig = ''
      auth_request_set $auth_cookie $upstream_http_set_cookie;
      add_header Set-Cookie $auth_cookie;
    '';
    # Override some proxy headers
    proxyHeaders = {
      "X-Forwarded-Port" = "";
      "X-Scheme" = "$scheme";
    };
  };

in
{
  # ACME (Let's Encrypt) configuration
  security.acme = {
    acceptTerms = true;
    defaults.email = "mjmaurer777@gmail.com";
  };

  services.nginx = {
    enable = true;

    # Could protect admin sites with this
    # tailscaleAuth = {
    #   enable = true;
    #   virtualHosts = [ "rvc.${host}" "invites.${host}" ];
    # };

    # TODO: use sendfile to serve protected media:
    # https://stackoverflow.com/questions/39744587/serve-protected-media-files-with-django

    # Global settings from nginx.conf.template and domain.include.template
    clientMaxBodySize = "80M";
    recommendedProxySettings = true; # Sets Host, X-Real-IP, X-Forwarded-For, X-Forwarded-Proto

    # From domain.include.template
    sslProtocols = "TLSv1.2 TLSv1.3";
    sslCiphers = "TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384";
    proxyHeaders = {
      "X-Forwarded-Host" = "$host";
      "X-Forwarded-Port" = "$server_port";
    };

    # Upstreams from nginx.conf.template
    upstreams = {
      "bobby-api".servers = {
        "${bobbyHost}:${bobbyPort}" = { };
      };
      "multiauth".servers = {
        "127.0.2.1:8000" = {
          weight = 5;
          max_fails = 0;
        };
        "127.0.2.1:8001" = {
          max_fails = 0;
        };
      };
    };

    # Internal servers listening on loopback addresses 
    appendHttpConfig = ''
      server {
          listen 127.0.2.1:8000;
          location / {
              proxy_pass http://${authExtraHost}:${authExtraPort}/jellyauth/;
              proxy_pass_request_body off;
              proxy_set_header        Content-Length "";
              proxy_set_header        X-Original-URI $request_uri;
          }
      }
      server {
          listen 127.0.2.1:8001;
          location / {
              proxy_pass http://${bobbyHost}:${bobbyPort}/api/user/;
              proxy_pass_request_body off;
              proxy_set_header Content-Length "";
              proxy_set_header        X-Original-URI $request_uri;
          }
      }
    '';

    # Virtual hosts
    virtualHosts = {
      # Main domain: bobby.place
      "${host}" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "http://bobby-api";
      };

      # automatic1111.bobby.place
      "automatic1111.${host}" = {
        forceSSL = true;
        enableACME = true;
        locations = lib.recursiveUpdate {
          "/" = subdomainSettings // {
            proxyPass = "http://${bobbyHost}:${automaticPort}/";
            authRequest = "/auth";
            extraConfig = subdomainSettings.extraConfig + "\nerror_page 403 = @error403;";
          };
        } authLocations;
      };

      # rvc.bobby.place
      "rvc.${host}" = {
        forceSSL = true;
        enableACME = true;
        locations = lib.recursiveUpdate {
          "/" = subdomainSettings // {
            proxyPass = "http://${bobbyHost}:${rvcPort}/";
            authRequest = "/auth";
            extraConfig = subdomainSettings.extraConfig + "\nerror_page 403 = @error403;";
          };
        } authLocations;
      };

      # plex.bobby.place
      "plex.${host}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = subdomainSettings // {
          proxyPass = "http://${earthHost}:${plexWebPort}/";
          extraConfig = subdomainSettings.extraConfig + "\nerror_page 403 = @error403;";
          proxyHeaders = lib.recursiveUpdate subdomainSettings.proxyHeaders {
            "X-Plex-Client-Identifier" = "$http_x_plex_client_identifier";
            "X-Plex-Device" = "$http_x_plex_device";
            "X-Plex-Device-Name" = "$http_x_plex_device_name";
            "X-Plex-Platform" = "$http_x_plex_platform";
            "X-Plex-Platform-Version" = "$http_x_plex_platform_version";
            "X-Plex-Product" = "$http_x_plex_product";
            "X-Plex-Token" = "$http_x_plex_token";
            "X-Plex-Version" = "$http_x_plex_version";
            "X-Plex-Nocache" = "$http_x_plex_nocache";
            "X-Plex-Provides" = "$http_x_plex_provides";
            "X-Plex-Device-Vendor" = "$http_x_plex_device_vendor";
            "X-Plex-Model" = "$http_x_plex_model";
          };
        };
      };

      # invites.bobby.place
      "invites.${host}" = {
        forceSSL = true;
        enableACME = true;
        locations = lib.recursiveUpdate {
          "/" = subdomainSettings // {
            proxyPass = "http://${earthHost}:${invitesPort}/";
            authRequest = "/auth";
            extraConfig = subdomainSettings.extraConfig + "\nerror_page 403 = @error403;";
          };
        } authLocations;
      };

      # jellyfin.bobby.place
      "jellyfin.${host}" = {
        forceSSL = true;
        enableACME = true;
        authRequest = "/auth";
        extraConfig = ''
          # Security / XSS Mitigation Headers
          add_header X-Frame-Options "SAMEORIGIN";
          add_header X-XSS-Protection "0";
          add_header X-Content-Type-Options "nosniff";
          # Permissions policy
          add_header Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), camera=(), clipboard-read=(), display-capture=(), document-domain=(), encrypted-media=(), gamepad=(), geolocation=(), gyroscope=(), hid=(), idle-detection=(), interest-cohort=(), keyboard-map=(), local-fonts=(), magnetometer=(), microphone=(), payment=(), publickey-credentials-get=(), serial=(), sync-xhr=(), usb=(), xr-spatial-tracking=()" always;
        '';
        locations = lib.recursiveUpdate {
          "/" = subdomainSettings // {
            proxyPass = "http://${earthHost}:${jellyfinWebPort}/";
            proxyBuffering = false;
          };
          "/Users" = {
            proxyPass = "http://${earthHost}:${jellyfinWebPort}";
          };
          "= /web/" = {
            proxyPass = "http://${earthHost}:${jellyfinWebPort}/web/index.html";
          };
          "/jellyauth" = {
            internal = true;
            proxyPass = "http://${authExtraHost}:${authExtraPort}/jellyauth/";
            proxyPassRequestBody = false;
            proxyHeaders."Content-Length" = "";
          };
        } authLocations;
      };
    };
  };
}
