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

          # networkmanager UI applet. May not work out of the box with waybar
          programs.nm-applet.enable = true;

          networking = {
            # Choosing networkmanager over systemd-networkd
            networkmanager = {
              enable = true;
              dns = "systemd-resolved";
              wifi.backend = "iwd";
            };

            nameservers = nameservers; # Not sure if this is actually used
            firewall = {
              enable = true;
              # Always allow traffic from Tailscale network
              trustedInterfaces = [ tailscaleInterface ];
            };

            # Disable wpa_supplicant as NetworkManager will handle wireless
            wireless.enable = false;
          };
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
