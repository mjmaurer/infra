{
  lib,
  config,
  isDarwin,
  derivationName,
  pkgs-latest,
  ...
}:
let
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

            networks = {
              "10-wired" = {
                matchConfig.Name = [
                  "en*"
                  "eth*"
                ];
                networkConfig = {
                  DHCP = "ipv4";
                  SendHostname = true;
                };
              };
              "20-wireless" = {
                matchConfig.Name = [
                  "wl*"
                ];
                networkConfig = {
                  DHCP = "ipv4";
                  SendHostname = true;
                };
              };
            };
          };

          # Chose systemd-networkd over dhcpcd (viable) and NetworkManager (imperative POS)
          services.dhcpcd.enable = false;
          networking = {
            # Need to to override hardware-configuration.nix, which sets this to true
            useDHCP = false;
            networkmanager.enable = false;

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
