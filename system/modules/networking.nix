{
  lib,
  config,
  isDarwin,
  derivationName,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.networking;
  hostname = derivationName;
  isNixOS = !isDarwin;
  tailscaleInterface = "tailscale0"; # Default
  # Must support DNSSEC
  nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];
in
{
  options.modules.networking = {
    wiredInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "networkctl list / ip link. A list of names for the primary wired network interfaces (e.g., eno1, eth0).";
      example = [
        "eth0"
        "eno1"
      ];
    };
    wirelessInterfaces = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = "A list of names for the wireless network interfaces (e.g., wlan0, wlp2s0). Set to null if no wireless interfaces are present or should be managed by systemd-networkd.";
      example = [ "wlan0" ];
    };
  };

  config = lib.mkMerge [
    {
      # In all systems, the flake depends on hostname already being set.
      # However, we still set it here to be explicit.
      networking.hostName = hostname;
    }

    (
      if isDarwin then
        {
          networking = {
            computerName = derivationName;
          };
          services.tailscale = {
            enable = true;
            package = pkgs-latest.tailscale;
            # overrideLocalDNS = true;
          };
        }
      else
        # NixOS
        {
          systemd.network = {
            enable = true;

            wait-online.timeout = 10;

            networks = lib.mkMerge [
              {
                "10-wired" = {
                  matchConfig.Name = cfg.wiredInterfaces;
                  networkConfig = {
                    DHCP = "ipv4";
                  };
                  dhcpV4Config = {
                    SendHostname = true;
                  };
                };
              }
              (lib.mkIf (cfg.wirelessInterfaces != null) {
                "20-wireless" = {
                  matchConfig.Name = cfg.wirelessInterfaces;
                  networkConfig = {
                    DHCP = "ipv4";
                  };
                  dhcpV4Config = {
                    SendHostname = true;
                  };
                };
              })
            ];
          };

          # Chose systemd-networkd over dhcpcd (viable) and NetworkManager (imperative POS)
          networking = {
            dhcpcd.enable = lib.mkForce false;
            # Need to to override hardware-configuration.nix, which sets this to true
            useDHCP = lib.mkForce false;
            networkmanager.enable = lib.mkForce false;

            # Enable wpa_supplicant
            wireless.enable = true;
            # Used by systemd-resolved
            nameservers = nameservers;

            firewall = {
              enable = true;
              # Always allow traffic from Tailscale network
              trustedInterfaces = [ tailscaleInterface ];
            };
          };
          # if we wanted dhcpcd:
          # dhcpcd.extraConfig = ''
          #   hostname ${derivationName}
          # '';

          # Enable systemd-resolved for DNS management
          services.resolved = {
            enable = true;
            dnssec = "allow-downgrade";
            fallbackDns = nameservers;
          };

          services.tailscale = {
            enable = true;
            package = pkgs-latest.tailscale;
            openFirewall = true;
            interfaceName = tailscaleInterface;
            useRoutingFeatures = lib.mkDefault "none";
            disableTaildrop = lib.mkDefault false;
            # extraUpFlags = [ "--login-server" ];

            authKeyFile = config.sops.secrets.oneTimeTailscaleAuthKey.path;
            authKeyParameters = {
              preauthorized = true;
            };
          };
          services.fail2ban = {
            enable = true;
            maxretry = 5;
            # Tailscale Range
            ignoreIP = [ "100.64.0.0/10" ];
            bantime = "15m";
            # jails = {
            #   nginx-nohome-iptables.settings = {
            #     filter = "nginx-noscript";
            #     action = ''iptables-multiport[name=HTTP, port="http,https"]'';
            #     logpath = "/var/log/nginx/error.log";
            #     backend = "auto";
            #     findtime = 600;
            #     bantime = 600;
            #     maxretry = 5;
            #   };
            # };
          };
          # Impermanence
          # environment.persistence = {
          #   "/persist".directories = [ "/var/lib/tailscale" ];
          # };
        }
    )
  ];
}
