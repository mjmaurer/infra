# Includes SSH, GPG, and Yubikey
{ osConfig ? null, lib, config, isDarwin, pkgs, ... }:
let
  cfg = config.modules.crypt;
  isNixOS = !isDarwin;
  gnupgDir = "${config.xdg.dataHome}/gnupg";
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
        (pkgs.writeScriptBin "ssh-host-bootstrap" (builtins.readFile ./scripts/ssh-host-bootstrap.sh))
      ];

      # TODO: https://developer.okta.com/blog/2021/07/07/developers-guide-to-gpg#use-your-gpg-key-on-multiple-computers

      modules.commonShell.shellAliases = {
        "ybs" = "yubi-switch";
        "gpgr" = "gpg-connect-agent reloadagent /bye";
      };

      programs = {
        gpg = {
          enable = true;
          homedir = gnupgDir;
          # publicKeys = [ { source = ./pubkeys.txt; } ];
          # TODO: consider mutableKeys = false;
          settings = import ./gpg.conf.nix;
          scdaemonSettings = {
            # Avoids the problem where GnuPG will repeatedly prompt
            # for the insertion of an already-inserted YubiKey
            # "disable-ccid" = true;
            # reader-port = "Yubico Yubikey";
            # log-file = "/tmp/gpg-scdaemon.log";
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
          };
      };
      # GPG keys (by keygrip ID) to expose via SSH
      # Replaces gpg-agent's `sshKeys` option
      home.file."${gnupgDir}/sshcontrol" = lib.mkIf (osConfig?sops) {
        source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates.gpg_sshcontrol.path;
      };
      home.activation.addGpgSshIdentity = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/.ssh"
        # This might break if the comment changes.
        run export _YBPK="$(${pkgs.openssh}/bin/ssh-add -L | grep "cardno")"
        if [ -n "$_YBPK" ]; then
          run echo "$_YBPK" > "$HOME/.ssh/id_rsa_yubikey.pub"
          run chmod 600 ~/.ssh/id_rsa_yubikey.pub
        else
          run echo "No GPG SSH key with 'none' comment found. Is your Yubikey inserted?"
        fi
      '';
    }
  ];
}
