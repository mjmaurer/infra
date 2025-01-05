{ lib, isDarwin, derivationName, ... }:
let
  # The hostname is the name of the derivation in flake.nix
  hostname = derivationName;
in
{
  networking = {
    networkmanager.enable = true;
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    # In all systems, the flake depends on hostname already being set.
    # However, we still set it here to be explicit.
    hostName = hostname;
  };
}
