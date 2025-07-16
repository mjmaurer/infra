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

  hstRoot = "/var/www/${hst}";

  # ─────────────── Domain / Sub-domain snippets for reuse ──────────────

  domainExtra = ''
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host  $host;
    proxy_set_header X-Forwarded-Port  $server_port;

    # TODO: use sendfile to serve protected media:
    # https://stackoverflow.com/questions/39744587/serve-protected-media-files-with-django
  '';

  subdomainExtra = ''
    # Websocket support
    proxy_http_version 1.1;
    proxy_cache_bypass         $http_upgrade;
    proxy_set_header Upgrade   $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header X-Scheme  $scheme;

    # Overrides
    proxy_set_header X-Forwarded-Port  "";

    proxy_buffers             4 256k;
    proxy_buffer_size         128k;
    proxy_busy_buffers_size   256k;

    client_max_body_size 100M;

    proxy_connect_timeout 120s;
    proxy_send_timeout    120s;
    proxy_read_timeout    120s;

    auth_request_set $auth_cookie $upstream_http_set_cookie;
    add_header Set-Cookie $auth_cookie; # need 'always'?

    location @error403 {
        return 302 https://${hst}/api/auth/redirect?next=$http_host$request_uri;
    }

    location /auth {
        proxy_pass http://bobby:${toString bobbyPort}/api/user/;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        # Might need to be X-Original-URI:
        proxy_set_header X-Original-URL $request_uri;
        proxy_next_upstream error http_503 non_idempotent;

        #proxy_pass http://authextra:${toString authextraPort}/jellyauth/;
        #proxy_pass http://multiauth/;
    }
  '';

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
    maxConcurrentRenewals = 10;
    defaults = {
      email = "mjmaurer777@gmail.com";
      group = "nginx";
    };
  };

  # Ensure the ACME web-root directory exists at boot
  systemd.tmpfiles.rules = [ "d ${hst} 0775 acme nginx - -" ];

  # ------------------------------  NGINX  ------------------------------
  services.nginx = {
    enable = true;

    # Could protect admin sites with this
    # tailscaleAuth = {
    #   enable = true;
    #   virtualHosts = [ "rvc.${host}" "invites.${host}" ];
    # };

    # package = pkgs.nginxMainline;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    commonHttpConfig = ''
      upstream bobby-api {
        server bobby:${toString bobbyPort};
      }

      upstream multiauth {
        server 127.0.2.1:8000 max_fails=0 weight=5;
        server 127.0.2.1:8001 max_fails=0;
        # Commenting out the 8001 actually makes it work for some reason
      }
    '';

    virtualHosts = {
      # --------------------------------------------------------------------------
      # Redirects
      # --------------------------------------------------------------------------
      # "redirect-root" = {
      #   serverName = hst;
      #   listen = [
      #     {
      #       addr = "0.0.0.0";
      #       port = 80;
      #     }
      #   ];
      #   locations = {
      #     # "/.well-known/acme-challenge/".root = acmeDir;
      #     "/".extraConfig = ''
      #       return 301 https://$host$request_uri;
      #     '';
      #   };
      # };

      # "redirect-wildcard" = {
      #   serverName = "*.${hst}";
      #   listen = [
      #     {
      #       addr = "0.0.0.0";
      #       port = 80;
      #     }
      #   ];
      #   locations = {
      #     # "/.well-known/acme-challenge/".root = acmeDir;
      #     "/".extraConfig = ''
      #       return 301 https://$host$request_uri;
      #     '';
      #   };
      # };

      # --------------------------------------------------------------------------
      # Internal
      # --------------------------------------------------------------------------
      # "auth-extra-8000" = {
      #   serverName = "_";
      #   listen = [
      #     {
      #       addr = "127.0.2.1";
      #       port = 8000;
      #     }
      #   ];
      #   locations."/".extraConfig = ''
      #     proxy_pass http://authextra:${toString authextraPort}/jellyauth/;
      #     proxy_pass_request_body off;
      #     proxy_set_header Content-Length "";
      #     proxy_set_header X-Original-URI $request_uri;
      #   '';
      # };

      # "auth-extra-8001" = {
      #   serverName = "_";
      #   listen = [
      #     {
      #       addr = "127.0.2.1";
      #       port = 8001;
      #     }
      #   ];
      #   locations."/".extraConfig = ''
      #     proxy_pass http://bobby:${toString bobbyPort}/api/user/;
      #     proxy_pass_request_body off;
      #     proxy_set_header Content-Length "";
      #     proxy_set_header X-Original-URI $request_uri;
      #   '';
      # };

      # --------------------------------------------------------------------------
      # Services
      # --------------------------------------------------------------------------

      # ------------------------------- Apex domain ------------------------------
      "${hst}" = {
        enableACME = true;
        forceSSL = true;
        root = hstRoot;
        extraConfig = domainExtra;
        # locations."/".proxyPass = "http://bobby-api";
        locations."/".extraConfig = ''
          return 301 https://google.com;
        '';
      };

      "plex.${hst}" = {
        enableACME = true;
        forceSSL = true;
        extraConfig = ''
          ${domainExtra}
          ${subdomainExtra}
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

      # "automatic1111.${hst}" = {
      #   enableACME = true;
      #   forceSSL = true;
      #   extraConfig = ''
      #     # Require upstream auth
      #     auth_request /auth;
      #     ${domainExtra}
      #     ${subdomainExtra}
      #   '';

      #   locations."/" = {
      #     proxyPass = "http://bobby:${toString automaticPort}/";
      #     extraConfig = ''error_page 403 = @error403;'';
      #   };
      # };

      # "rvc.${hst}" = {
      #   enableACME = true;
      #   forceSSL = true;
      #   extraConfig = ''
      #     # Require upstream auth
      #     auth_request /auth;
      #     ${domainExtra}
      #     ${subdomainExtra}
      #   '';

      #   locations."/" = {
      #     proxyPass = "http://bobby:${toString rvcPort}/";
      #     extraConfig = ''error_page 403 = @error403;'';
      #   };
      # };
    };
  };
}
