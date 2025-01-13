# Includes SSH, GPG, and Yubikey
{ lib, config, isDarwin, pkgs, ... }:
let
  cfg = config.modules.crypt;
  isNixOS = !isDarwin;
in
{
  options.modules.crypt = { };

  config = lib.mkMerge [
    {
      home.packages = [
        pkgs.yubikey-personalization
        pkgs.yubikey-manager
        (pkgs.writeScriptBin "yubi-conf" (builtins.readFile ./scripts/yubikey-configure.sh))
        (pkgs.writeScriptBin "yubi-switch" (builtins.readFile ./scripts/yubikey-switch.sh))
        (pkgs.writeScriptBin "yubi-addgpg" (builtins.readFile ./scripts/yubikey-addgpg.sh))
      ];

      modules.commonShell.shellAliases = {
        "ybs" = "yubi-switch";
        "gpgr" = "gpg-connect-agent reloadagent /bye";
      };

      programs = {
        gpg = {
          enable = true;
          homedir = "${config.xdg.dataHome}/gnupg";
          # publicKeys = [ { source = ./pubkeys.txt; } ];
          # TODO: consider mutableKeys = false;
          settings = import ./gpg.conf.nix;
          scdaemonSettings = {
            # Avoids the problem where GnuPG will repeatedly prompt
            # for the insertion of an already-inserted YubiKey
            # "disable-ccid" = true;
            # reader-port = "Yubico Yubikey";
            log-file = "/tmp/gpg-scdaemon.log";
          };
        };
        ssh = {
          enable = true;
          includes = [
            # For manual/local configurations
            "~/.ssh/config.local"
          ];
          # Needed for mac?
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
            enableScDaemon = true;
            # GPG keys (by keygrip ID) to expose via SSH
            sshKeys = [ ];
          };
      };
    }
  ];
}
