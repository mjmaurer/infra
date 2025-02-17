{ config, pkgs, ... }:

{
  imports = [ ./linux.nix ];

  modules.commonShell = { machineName = config.networking.hostName; };

  # services = {
  #   gpg-agent = {
  #     enable = true;
  #     pinentryFlavor = "gtk2";
  #   };
  # };
}
