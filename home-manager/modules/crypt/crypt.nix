# Includes SSH, GPG, and Yubikey
{ lib, config, isDarwin, pkgs, ... }:
let
  cfg = config.modules.crypt;
  isNixOS = !isDarwin;
  gpg-agent-conf = pkgs.writeText "gpg-agent.conf" ''
    pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses
  '';
in
{
  options.modules.crypt = { };

  config = lib.mkMerge [
    {

      home.packages = [ pkgs.yubikey-personalization pkgs.yubikey-manager ];

      programs = {
        gpg = {
          enable = true;
          enableSSHSupport = true;
        };
        ssh = {
          enable = true;
          includes = [
            # For manual/local configurations
            "~/.ssh/config.local"
          ];
          # addKeysToAgent = "yes";
        };
      };
      services = {
        ssh-agent.enable = false;
        gpg-agent =
          let
            cacheTtl = 60 * 60;
            maxCacheTtl = 60 * 60 * 48;
          in
          {
            enable = true;
            defaultCacheTtl = cacheTtl;
            defaultCacheTtlSsh = cacheTtl;
            maxCacheTtl = maxCacheTtl;
            maxCacheTtlSsh = maxCacheTtl;
            enableZshIntegration = true;
            pinentryPackage = pkgs.pinentry-curses;
            # Prefer gpg-agent over ssh-agent
            enableSshSupport = true;
            # Smartcard support. This talks to pcscd:
            enableScDaemon = false;
            extraConfig = builtins.readFile ./gpg.conf;
          };
      };

      # Set up the shell for making keys.
      # interactiveShellInit = ''
      #   unset HISTFILE
      #   export GNUPGHOME=/run/user/$(id -u)/gnupg
      #   [ -d $GNUPGHOME ] || install -m 0700 -d $GNUPGHOME
      #   cp ${pkgs.drduh-gpg-conf}/gpg.conf $GNUPGHOME/gpg.conf
      #   cp ${gpg-agent-conf}  $GNUPGHOME/gpg-agent.conf
      #   echo "\$GNUPGHOME is $GNUPGHOME"
      # '';
    }
  ];
}
