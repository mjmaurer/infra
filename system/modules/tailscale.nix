{ lib, isDarwin, ... }:
let
  tailscalePort = 41641;
  isNixOS = !isDarwin;
in
lib.mkMerge [
  {
    services.tailscale = {
      enable = true;
    };
  }
  (lib.optionalAttrs isNixOS {
    services.tailscale = {
      port = tailscalePort;
      # useRoutingFeatures = lib.mkDefault "client";
      # extraUpFlags = [ "--login-server" ];
    };

    # services.tailscale.openFirewall = true; might be better
    networking.firewall = {
      # Facilitate firewall punching
      allowedUDPPorts = [ tailscalePort ];
    };
    environment.persistence = {
      "/persist".directories = [ "/var/lib/tailscale" ];
    };
  })
]
