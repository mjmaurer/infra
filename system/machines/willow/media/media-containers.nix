{
  lib,
  config,
  pkgs,
  ...
}:

let
  # === Adjustable paths =====================================================
  # Consolidate host paths here so you only need to change them once.
  hostConfDir = "/srv/media/config"; # formerly $HOST_CONF_DIR
  hostDataDir = "/srv/media/data"; # formerly $HOST_DATA_DIR
  containerDataDir = "/data"; # formerly $CONTAINER_DATA_DIR
  vpnOvpnDir = "/srv/media/vpn/ovpn"; # formerly $VPN_OVPNDIR
  vpnWgDir = "/srv/media/vpn/wg"; # formerly $VPN_WGDIR

  mediaGid = ;

  # Default (shared) UID/GID layout — tweak if these collide on your system.
  allMediaGroups = [
    "content"
    "rents"
    "usen"
  ];

  # Convenience helper that turns the attr‑set above into `users.users` entries
  mkUser = idx: extraGroups: {
    inherit extraGroups;
    uid = 105 + idx;
    isSystemUser = true; # Does nothing since uid is set above
  };
in
{
  users.users = {
    # If group is unset, uses nixos default of self-named group.
    nginx = mkUser 0 [ ];
    prowlarr = mkUser 1 [ ];
    overseerr = mkUser 2 [ ];
    requestrr = mkUser 3 [ ];
    radarr = mkUser 4 allMediaGroups;
    sonarr = mkUser 5 allMediaGroups;
    readarr = mkUser 6 allMediaGroups;
    bazarr = mkUser 7 allMediaGroups;
    qbit = mkUser 8 ["rents"];
    sab = mkUser 9 ["usen"];
    plex = mkUser 10 ["content"];
    wizarr = mkUser 11 [ ];
    flaresolverr = mkUser 12 [ ];
  };

  # === Secrets ==============================================================
  # All non‑default env vars live in one SOPS‑managed dotenv.
  sops.secrets."media/containers.env" = {
    # Path to your encrypted secrets file (edit to taste):
    sopsFile = ./secrets.yaml;
    mode = "0640";
    group = "media";
  };

  # === High‑level virtualisation tweaks =====================================
  virtualisation = {
    oci-containers.backend = "podman"; # switch from docker to podman
    containers.cgroupV2 = true; # keep systemd happy

    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune.enable = true;
    };
  };

  # === Common environment (shared umask/timezone) ===========================
  environment.variables = {
    TZ = "America/New_York"; # override if you live elsewhere
    UMASK = "002"; # folders 775, files 664 per guide
  };

  # === Optional: nightly image refresh ======================================
  systemd.timers.podmanAutoUpdate = {
    wantedBy = [ "timers.target" ];
    partOf = [ "podman-auto-update.service" ];
    timerConfig = {
      OnCalendar = "03:45";
      Persistent = true;
    };
  };
  systemd.services.podman-auto-update = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman auto-update --replace";
    };
  };

  # === Network shared by the media‑stack ====================================
  virtualisation.oci-containers.networks.media = { };

  # === Container definitions ===============================================
  virtualisation.oci-containers.containers = {

    # -- qBittorrent VPN -----------------------------------------------------
    qbit = {
      image = "ghcr.io/binhex/arch-qbittorrentvpn:latest";
      hostname = config.networking.hostName;
      user = "qbit:qbit";
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      environment = {
        STRICT_PORT_FORWARD = "yes";
        VPN_INPUT_PORTS = "1234";
        VPN_OUTPUT_PORTS = "5678";
        DEBUG = "true";
        UMASK = "000";
        WEBUI_PORT = "$QBITTORRENTVPN_PORT_8080"; # still comes from secrets
      };
      ports = [
        "51413:51413"
        "51413:51413/udp"
        "6881:6881"
        "6881:6881/udp"
        "8118:8118"
        "$QBITTORRENTVPN_PORT_8080:$QBITTORRENTVPN_PORT_8080"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/qbittorrentvpn:/config"
        "${hostDataDir}/torrents:${containerDataDir}/torrents"
        "${vpnOvpnDir}:/config/openvpn"
        "${vpnWgDir}:/config/wireguard"
      ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--cap-add=SYS_MODULE"
        "--privileged"
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- SABnzbd VPN ---------------------------------------------------------
    sab = {
      image = "ghcr.io/binhex/arch-sabnzbdvpn:latest";
      hostname = config.networking.hostName;
      user = "${toString uids.sab}:${toString mediaGid}";
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      environment = {
        STRICT_PORT_FORWARD = "yes";
        VPN_INPUT_PORTS = "1234";
        VPN_OUTPUT_PORTS = "5678";
        DEBUG = "true";
        UMASK = "000";
        VPN_ENABLED = "no";
      };
      ports = [
        "8090:8090"
        "8091:8080"
        "$SAB_PORT_8118:8118"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/sabnzbdvpn:/config"
        "${hostDataDir}/usenet:${containerDataDir}/usenet"
        "${vpnOvpnDir}:/config/openvpn"
        "${vpnWgDir}:/config/wireguard"
      ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--cap-add=SYS_MODULE"
        "--privileged"
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Reverse‑proxy (media‑nginx) ----------------------------------------
    media-nginx = {
      image = "docker.io/library/nginx:latest";
      user = "${toString uids.nginx}:${toString mediaGid}";
      environment = {
        QBITTORRENTVPN_PORT_8080 = "$QBITTORRENTVPN_PORT_8080";
        SAB_PORT_8080 = "$SAB_PORT_8080";
        PLEX_WEB_PORT = "$PLEX_WEB_PORT";
        NGINX_ENVSUBST_TEMPLATE_SUFFIX = ".template";
      };
      ports = [
        "$QBITTORRENTVPN_PROXY_PORT:$QBITTORRENTVPN_PORT_8080"
        "$SAB_PROXY_PORT:$SAB_PORT_8080"
      ];
      volumes = [
        "${toString ./nginx}/nginx.conf.template:/etc/nginx/templates/nginx.conf.template"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Plex ---------------------------------------------------------------
    plex = {
      image = "lscr.io/linuxserver/plex:latest";
      user = "${toString uids.plex}:${toString mediaGid}";
      hostname = config.networking.hostName;
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      environment = {
        PLEX_CLAIM = "https://plex.tv/claim";
        VERSION = "docker";
      };
      devices = [ "/dev/dri:/dev/dri" ];
      ports = [
        "1900:1900/udp"
        "3005:3005"
        "$PLEX_WEB_PORT:32400"
        "32410:32410/udp"
        "32412:32412/udp"
        "32413:32413/udp"
        "32414:32414/udp"
        "32469:32469"
        "33400:33400"
        "8324:8324"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/plex:/config"
        "${hostDataDir}/media:/data/media"
      ];
      extraOptions = [
        "--device=/dev/dri"
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Radarr -------------------------------------------------------------
    radarr = {
      image = "lscr.io/linuxserver/radarr:latest";
      user = "${toString uids.radarr}:${toString mediaGid}";
      ports = [ "7878:7878" ];
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/radarr:/config"
        "${hostDataDir}:${containerDataDir}"
      ];
      extraOptions = [
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Sonarr -------------------------------------------------------------
    sonarr = {
      image = "lscr.io/linuxserver/sonarr:latest";
      user = "${toString uids.sonarr}:${toString mediaGid}";
      ports = [ "8989:8989" ];
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/sonarr:/config"
        "${hostDataDir}:${containerDataDir}"
      ];
      extraOptions = [
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Prowlarr -----------------------------------------------------------
    prowlarr = {
      image = "lscr.io/linuxserver/prowlarr:latest";
      user = "${toString uids.prowlarr}:${toString mediaGid}";
      ports = [ "9696:9696" ];
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/prowlarr:/config"
        "${hostDataDir}:${containerDataDir}"
      ];
      extraOptions = [
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Overseerr ----------------------------------------------------------
    overseerr = {
      image = "lscr.io/linuxserver/overseerr:latest";
      user = "${toString uids.overseerr}:${toString mediaGid}";
      ports = [ "5055:5055" ];
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/overseerr:/config"
      ];
      extraOptions = [
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Readarr ------------------------------------------------------------
    readarr = {
      image = "lscr.io/linuxserver/readarr:develop";
      user = "${toString uids.readarr}:${toString mediaGid}";
      ports = [ "8787:8787" ];
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/readarr:/config"
        "${hostDataDir}:${containerDataDir}"
      ];
      extraOptions = [
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Bazarr -------------------------------------------------------------
    bazarr = {
      image = "lscr.io/linuxserver/bazarr:latest";
      user = "${toString uids.bazarr}:${toString mediaGid}";
      ports = [ "6767:6767" ];
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/bazarr:/config"
        "${hostDataDir}/media:${containerDataDir}/media"
      ];
      extraOptions = [
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Requestrr ----------------------------------------------------------
    requestrr = {
      image = "docker.io/thomst08/requestrr:latest";
      user = "${toString uids.requestrr}:${toString mediaGid}";
      ports = [ "4545:4545" ];
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${hostConfDir}/requestrr:/root/config"
        "${hostDataDir}:${containerDataDir}"
      ];
      extraOptions = [
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- Wizarr -------------------------------------------------------------
    wizarr = {
      image = "ghcr.io/wizarrrr/wizarr:latest";
      user = "${toString uids.wizarr}:${toString mediaGid}";
      ports = [ "5690:5690" ];
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      volumes = [
        "${hostConfDir}/wizarr:/data/database"
      ];
      extraOptions = [
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };

    # -- FlareSolverr -------------------------------------------------------
    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      user = "${toString uids.flaresolverr}:${toString mediaGid}";
      ports = [ "8191:8191" ];
      environmentFiles = [ config.sops.secrets."media/containers.env".path ];
      environment = {
        LOG_LEVEL = "info";
      };
      extraOptions = [
        "--log-opt=max-file=${DOCKERLOGGING_MAXFILE}"
        "--log-opt=max-size=${DOCKERLOGGING_MAXSIZE}"
      ];
      restartPolicy = "unless-stopped";
      networks = [ "media" ];
    };
  };
}
