{ config, pkgs, ... }:

{
  imports = [ ./linux.nix ];

  modules.commonShell = { };

  # services = {
  #   gpg-agent = {
  #     enable = true;
  #     pinentryFlavor = "gtk2";
  #   };
  # };
}
