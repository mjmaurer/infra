{
  lib,
  config,
  pkgs,
  ...
}:

let
  # === Adjustable paths =====================================================
  # Consolidate host paths here so you only need to change them once.
  hostMediaRoot = "/media";
  hostMediaContent = "${hostMediaRoot}/content";
  hostMediaRents = "${hostMediaRoot}/rents";
  hostMediaUsen = "${hostMediaRoot}/usen";

  containerMediaRoot = "/media";
  containerMediaContent = "${containerMediaRoot}/content";
  containerMediaRents = "${containerMediaRoot}/rents";
  containerMediaUsen = "${containerMediaRoot}/usen";

  hostConfigDir = config.modules.duplicacy.repos."media-config".localRepoPath;

  cfg = config.modules.mediaStack;

  # Convenience helper that turns the attr‑set above into `users.users` entries
  mkUser = idx: name: extraGroups: {
    users.${name} = {
      group = name;
      extraGroups = extraGroups ++ [
        cfg.groups.general
        "podman"
      ];
      uid = 105 + idx;
      # gives the user a systemd user session
      # linger = true;
      isSystemUser = true; # Does nothing since uid is set above
      home = "/var/lib/service-users/${name}";
      createHome = true;
      homeMode = "0750";
    };
    groups.${name}.gid = 105 + idx;
  };

  mkContainer =
    {
      user ? null,
      group ? cfg.groups.general,
      runAsUser ? false,
    }:
    local:
    let
      template = {
        hostname = config.networking.hostName;
        # This apparently doesn't work with linuxserver.io images:
        # https://docs.linuxserver.io/general/understanding-puid-and-pgid/
        user = lib.mkIf (user != null && group != null && runAsUser) "${user}:${group}";
        pull = "newer";

        # NOTE: I gave up on rootless. See 9fd2c5c for closest attempt.
        # Need linger and subgid on user, and might want to run as a single 'media' user
        # and then use PUID/PGID to set the container user.
        # If so, would need to figure out the uid/gid mapping for the sub ranges.
        # podman.user = user;
        autoRemoveOnStop = true;
        # networks = [ "media" ];
        extraOptions = [
          "--replace"
          # "--restart=unless-stopped" # Removed: Systemd handles this
        ];
        environment = {
          # Set the container user to the same as the host user
          PUID = lib.mkIf (user != null) "${toString config.users.users.${user}.uid}";
          PGID = lib.mkIf (user != null && group != null) "${toString config.users.groups.${group}.gid}";
          TZ = "America/New_York";
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
        ];
      };
    in
    lib.mkMerge [
      template
      local
    ];
in
{
  # === Users =================================================================
  users = lib.foldl lib.recursiveUpdate { } [
    (mkUser 1 "prowlarr" [ ])
    (mkUser 2 "overseerr" [ ])
    (mkUser 3 "requestrr" [ ])
    (mkUser 4 "radarr" [ ])
    (mkUser 5 "sonarr" [ ])
    (mkUser 6 "readarr" [ ])
    (mkUser 7 "bazarr" [ ])
    (mkUser 8 "qbit" [ ])
    (mkUser 9 "sab" [ ])
    (mkUser 10 "plex" [
      "video"
      "render"
    ])
    (mkUser 11 "wizarr" [ ])
    (mkUser 12 "byparr" [ ])
    (mkUser 13 "unpackerr" [ ])
  ];

  # === Optional: nightly image refresh ======================================
  # systemd.timers.podmanAutoUpdate = {
  #   wantedBy = [ "timers.target" ];
  #   partOf = [ "podman-auto-update.service" ];
  #   timerConfig = {
  #     OnCalendar = "03:45";
  #     Persistent = true;
  #   };
  # };
  # systemd.services.podman-auto-update = {
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.podman}/bin/podman auto-update --replace";
  #   };
  # };

  # === Container definitions ===============================================
  virtualisation.oci-containers.containers = lib.mkIf cfg.enableContainers {

    # -- qBittorrent VPN -----------------------------------------------------
    qbit = mkContainer { user = "qbit"; } {
      image = "ghcr.io/binhex/arch-qbittorrentvpn:latest";
      environmentFiles = [ config.sops.templates."qbit.env".path ];
      environment = {
        WEBUI_PORT = cfg.ports.qbitWeb;
        STRICT_PORT_FORWARD = "yes";
        # DEBUG = "true";
        UMASK = "000"; # cfg.umask; https://github.com/binhex/arch-qbittorrentvpn/issues/260
        ENABLE_PRIVOXY = "yes";
        VPN_ENABLED = "yes";
        VPN_INPUT_PORTS = "1234";
        VPN_OUTPUT_PORTS = "5678";
        NAME_SERVERS = "${lib.concatStringsSep "," config.networking.nameservers}";
        # Connect to webui from tailscale:
        LAN_NETWORK = config.modules.networking.tailscaleIPRange;
      };
      ports = [
        "51413:51413"
        "51413:51413/udp"
        "6881:6881"
        "6881:6881/udp"
        "8118:8118"
        "${cfg.ports.qbitWeb}:${cfg.ports.qbitWeb}"
      ];
      volumes = [
        "${hostMediaRents}:${containerMediaRents}"
        "${hostConfigDir}/qbit:/config"
        "${hostConfigDir}/.openvpn:/config/openvpn"
        "${hostConfigDir}/.wireguard:/config/wireguard"
      ];
      capabilities = {
        "NET_ADMIN" = true;
        "SYS_MODULE" = true;
      };
      privileged = true;
      extraOptions = [
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
      ];
    };
    # -- SABnzbd VPN ---------------------------------------------------------
    sab = mkContainer { user = "sab"; } {
      image = "ghcr.io/binhex/arch-sabnzbdvpn:latest";
      environment = {
        STRICT_PORT_FORWARD = "yes";
        VPN_INPUT_PORTS = "1234";
        VPN_OUTPUT_PORTS = "5678";
        # DEBUG = "true";
        UMASK = cfg.umask;
        VPN_ENABLED = "no";
        ENABLE_PRIVOXY = "yes";
        NAME_SERVERS = "${lib.concatStringsSep "," config.networking.nameservers}";
        # Connect to webui from tailscale:
        LAN_NETWORK = config.modules.networking.tailscaleIPRange;
      };
      ports = [
        "8090:8090"
        "${cfg.ports.sabWeb}:8080"
        "${cfg.ports.sab8118}:8118"
      ];
      volumes = [
        "${hostMediaUsen}:${containerMediaUsen}"
        "${hostConfigDir}/sab:/config"
        "${hostConfigDir}/.openvpn:/config/openvpn"
        "${hostConfigDir}/.wireguard:/config/wireguard"
      ];
      capabilities = {
        "NET_ADMIN" = true;
        "SYS_MODULE" = true;
      };
      privileged = true;
      extraOptions = [
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
      ];
    };

    # -- Plex ---------------------------------------------------------------
    plex = mkContainer { user = "plex"; } {
      image = "lscr.io/linuxserver/plex:latest";
      environment = {
        PLEX_CLAIM = "https://plex.tv/claim";
        VERSION = "docker";
      };
      devices = [ "/dev/dri:/dev/dri" ];
      ports = [
        "1900:1900/udp"
        "3005:3005"
        "${cfg.ports.plexWeb}:32400"
        "32410:32410/udp"
        "32412:32412/udp"
        "32413:32413/udp"
        "32414:32414/udp"
        "32469:32469"
        "33400:33400"
        "8324:8324"
      ];
      volumes = [
        "${hostMediaContent}:${containerMediaContent}"
        "${hostConfigDir}/plex:/config"
      ];
    };

    # -- Radarr -------------------------------------------------------------
    radarr = mkContainer { user = "radarr"; } {
      image = "lscr.io/linuxserver/radarr:latest";
      ports = [ "7878:7878" ];
      volumes = [
        "${hostMediaRoot}:${containerMediaRoot}"
        "${hostConfigDir}/radarr:/config"
      ];
    };

    # -- Sonarr -------------------------------------------------------------
    # sqlite3 sonarr.db "update EpisodeFiles set MediaInfo=NULL where json_valid(MediaInfo)=0;"
    # sqlite3 sonarr.db "SELECT Id, RelativePath FROM EpisodeFiles WHERE json_valid(MediaInfo) = 0;"
    sonarr = mkContainer { user = "sonarr"; } {
      image = "lscr.io/linuxserver/sonarr:latest";
      ports = [ "8989:8989" ];
      volumes = [
        "${hostMediaRoot}:${containerMediaRoot}"
        "${hostConfigDir}/sonarr:/config"
      ];
    };

    # -- Prowlarr -----------------------------------------------------------
    prowlarr = mkContainer { user = "prowlarr"; } {
      image = "lscr.io/linuxserver/prowlarr:latest";
      ports = [ "9696:9696" ];
      volumes = [
        "${hostConfigDir}/prowlarr:/config"
      ];
    };

    # -- Overseerr ----------------------------------------------------------
    overseerr = mkContainer { user = "overseerr"; } {
      image = "lscr.io/linuxserver/overseerr:latest";
      ports = [ "5055:5055" ];
      volumes = [
        "${hostConfigDir}/overseerr:/config"
      ];
    };

    # -- Readarr ------------------------------------------------------------
    # readarr = mkContainer { user = "readarr"; } {
    #   image = "lscr.io/linuxserver/readarr:amd64-develop";
    #   ports = [ "8787:8787" ];
    #   volumes = [
    #     "${hostConfigDir}/readarr:/config"
    #   ];
    # };

    # -- Bazarr -------------------------------------------------------------
    bazarr = mkContainer { user = "bazarr"; } {
      image = "lscr.io/linuxserver/bazarr:latest";
      ports = [ "6767:6767" ];
      volumes = [
        "${hostMediaContent}:${containerMediaContent}"
        "${hostConfigDir}/bazarr:/config"
      ];
    };

    # -- Requestrr ----------------------------------------------------------
    requestrr = mkContainer { user = "requestrr"; } {
      image = "docker.io/thomst08/requestrr:latest";
      ports = [ "4545:4545" ];
      volumes = [
        "${hostConfigDir}/requestrr:/root/config"
      ];
    };

    # -- Wizarr -------------------------------------------------------------
    # wizarr = mkContainer { user = "wizarr"; } {
    #   image = "ghcr.io/wizarrrr/wizarr:latest";
    #   ports = [ "5690:5690" ];
    #   volumes = [
    #     "${hostConfigDir}/wizarr:/data/database"
    #   ];
    # };

    # -- Byparr -------------------------------------------------------
    # NOTE: Currently nonfunctional: https://trash-guides.info/Prowlarr/prowlarr-setup-flaresolverr/
    byparr = mkContainer { user = "byparr"; } {
      image = "ghcr.io/thephaseless/byparr:latest";
      ports = [ "8191:8191" ];
      environment = {
        LOG_LEVEL = "info";
        USE_HEADLESS = "true";
      };
    };
  };

  systemd.tmpfiles.rules = [
    # Create unpackerr config dir so it can write logs
    "d ${hostConfigDir}/unpackerr 0755 unpackerr media - -"
  ];

  systemd.services.unpackerr = {
    description = "Unpackerr";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = config.users.users.unpackerr.name;
      Group = cfg.groups.general;
      ExecStart = "${pkgs.unpackerr}/bin/unpackerr";
      EnvironmentFile = config.sops.templates."unpackerr.env".path;
      Restart = "on-failure";
    };
  };

  sops =
    let
      test = 1;
      mkSecret = user: {
        owner = config.users.users.${user}.name;
        group = "root";
        mode = "0440";
        sopsFile = ../secrets.yaml;
      };
    in
    {
      secrets = {
        vpnClient = mkSecret "qbit";
        vpnProv = mkSecret "qbit";
        vpnUser = mkSecret "qbit";
        vpnPass = mkSecret "qbit";
        vpnOptions = mkSecret "qbit";

        sonarrApiKey = mkSecret "unpackerr";
        radarrApiKey = mkSecret "unpackerr";
      };

      templates = {
        "qbit.env" = {
          owner = config.users.users.qbit.name;
          group = "root";
          mode = "0440";
          content = ''
            VPN_CLIENT=${config.sops.placeholder.vpnClient}
            VPN_PROV=${config.sops.placeholder.vpnProv}
            VPN_USER=${config.sops.placeholder.vpnUser}
            VPN_PASS=${config.sops.placeholder.vpnPass}
            VPN_OPTIONS=${config.sops.placeholder.vpnOptions}
          '';
        };
        "unpackerr.env" = {
          owner = config.users.users.unpackerr.name;
          group = "root";
          mode = "0440";
          content = ''
            UN_LOG_FILE=${hostConfigDir}/unpackerr/unpackerr.log
            UN_SONARR_0_URL=http://localhost:8989
            UN_SONARR_0_API_KEY=${config.sops.placeholder.sonarrApiKey}
            UN_SONARR_0_PROTOCOLS=torrent,usenet
            UN_SONARR_0_PATHS_0=${hostMediaRents}
            UN_SONARR_0_PATHS_1=${hostMediaUsen}
            UN_RADARR_0_URL=http://localhost:7878
            UN_RADARR_0_API_KEY=${config.sops.placeholder.radarrApiKey}
            UN_RADARR_0_PROTOCOLS=torrent,usenet
            UN_RADARR_0_PATHS_0=${hostMediaRents}
            UN_RADARR_0_PATHS_1=${hostMediaUsen}
            # UN_FOLDERS_INTERVAL=2m
            # UN_FOLDER_0_PATH=${hostMediaRents}
            # UN_FOLDER_1_PATH=${hostMediaUsen}
          '';
        };
      };
    };
}
