{
  lib,
  config,
  isDarwin,
  derivationName,
  pkgs,
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
    tailscaleIPRange = lib.mkOption {
      type = lib.types.str;
      default = "100.64.0.0/10";
      description = "The IP range used by Tailscale.";
    };
    # On client, need to either:
    # - `tailscale up --accept-routes=true`
    # - or in GUI:
    # On Admin page:
    # - For machine: approve the routes
    # - Add to access control list
    tailscaleSubnetRouter = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable this machine as a Tailscale subnet router.";
          };
          subnet = lib.mkOption {
            type = lib.types.str;
            description = "Subnet to advertise via Tailscale";
          };
        };
      };
      description = "Configuration for ensuring the local repository path exists.";
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
          # Tailscale is managed by Homebrew on Darwin
        }
      else
        # NixOS
        {
          systemd.network = {
            enable = true;

            wait-online = {
              anyInterface = true;
              timeout = 10;
            };

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
            wireless.enable = (cfg.wirelessInterfaces != null);
            # Used by systemd-resolved
            nameservers = nameservers;

            # Could disable ipv6 if worried about attack surface
            # enableIPv6 = false;

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

          # ---- NOTE -----: Might need to refresh the authKeyFile for a headless machine when changing this
          services.tailscale = {
            enable = true;
            package = pkgs.tailscale;
            openFirewall = true;
            interfaceName = tailscaleInterface;
            useRoutingFeatures = if cfg.tailscaleSubnetRouter.enabled then "server" else "none";
            disableTaildrop = lib.mkDefault false;
            extraUpFlags = lib.optionals cfg.tailscaleSubnetRouter.enabled [
              "--advertise-routes=${cfg.tailscaleSubnetRouter.subnet}"
            ];
            authKeyFile = config.sops.secrets.oneTimeTailscaleAuthKey.path;
          };
          services.fail2ban = {
            enable = true;
            maxretry = 5;
            # Tailscale Range
            ignoreIP = [ cfg.tailscaleIPRange ];
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
