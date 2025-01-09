{ lib, isDarwin, derivationName, ... }:
let
  # The hostname is the name of the derivation in flake.nix
  hostname = derivationName;
  isNixOS = !isDarwin;
in
lib.mkMerge [
  {
    # In all systems, the flake depends on hostname already being set.
    # However, we still set it here to be explicit.
    networking.hostName = hostname;
  }
  (lib.optionalAttrs isNixOS {
    networking = {
      networkmanager.enable = true;
      nameservers = [ "1.1.1.1" "8.8.8.8" ];
    };
  })
  (lib.optionalAttrs isDarwin {
    networking = {
      computerName = derivationName;
    };
    # Don't think we need this. It was requiring sudo access every switch.
    # system.defaults.smb.NetBIOSName = derivationName;
  })
]
