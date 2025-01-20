# Includes SSH, GPG, and Yubikey
{ osConfig ? null, lib, config, isDarwin, pkgs, ... }:
let
  cfg = config.modules.crypt;
  isNixOS = !isDarwin;
  gnupgDir = "${config.xdg.dataHome}/gnupg";
in {
  options.modules.crypt = { };

  config = lib.mkMerge [{
    home.packages = [
      pkgs.yubikey-personalization
      pkgs.yubikey-manager
      (pkgs.writeScriptBin "yubi-conf"
        (builtins.readFile ./scripts/yubikey-configure.sh))
      (pkgs.writeScriptBin "yubi-switch"
        (builtins.readFile ./scripts/yubikey-switch.sh))
      (pkgs.writeScriptBin "yubi-addgpg"
        (builtins.readFile ./scripts/yubikey-addgpg.sh))
      (pkgs.writeScriptBin "ssh-host-bootstrap"
        (builtins.readFile ./scripts/ssh-host-bootstrap.sh))
      (pkgs.writeScriptBin "gpg-new-key"
        (builtins.readFile ./scripts/gpg-new-key.sh))
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
          # like: "gpg: OpenPGP card not available: Operation not supported by device"
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
      gpg-agent = let
        cacheTtl = 60 * 60;
        maxCacheTtl = 60 * 60 * 48;
      in {
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
    home.file."${gnupgDir}/sshcontrol" = lib.mkIf (osConfig ? sops) {
      source = config.lib.file.mkOutOfStoreSymlink
        osConfig.sops.templates.gpg_sshcontrol.path;
    };
    home.sessionVariablesExtra =
      lib.mkIf config.services.gpg-agent.enableSshSupport ''
        if [[ -z "''${SSH_AUTH_SOCK}" ]] || [[ "''${SSH_AUTH_SOCK}" =~ '^/private/tmp/com\.apple\.launchd\.[^/]+/Listeners$' ]]; then
          export SSH_AUTH_SOCK="$(${config.programs.gpg.package}/bin/gpgconf --list-dirs agent-ssh-socket)"
        fi
      '';
    home.activation.addGpgSshIdentity =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/.ssh"
        # This might break if the comment changes.
        # This might be better: gpg --export-ssh-key mjmaurer777@gmail.com
        run export _YBPK="$(${pkgs.openssh}/bin/ssh-add -L | grep "cardno")"
        if [ -n "$_YBPK" ]; then
          run echo "$_YBPK" > "$HOME/.ssh/id_rsa_yubikey.pub"
          run chmod 600 ~/.ssh/id_rsa_yubikey.pub
        else
          run echo "No GPG SSH key with 'cardno' comment found."
          run echo "It's possible that ssh-agent is interfering with gpg-agent. See `home-manager/.../crypt.nix`"
          run echo "You also might need to nix-rebuild with your Yubikey inserted."

          # Mac runs ssh-agent natively, which sets SSH_AUTH_SOCK.
          # We attempt to stop it via variable above.
          # Otherwise, we need to stop it, and re-start gpg-agent.

          # mdfind ssh-agent|grep plist
          # launchctl unload -w /System/Library/LaunchAgents/com.openssh.ssh-agent.plist
          # sudo launchctl disable system/com.openssh.ssh-agent

          # exec zsh (or set SSH_AUTH_SOCK manually)
          # gpgr
        fi
      '';
  }];
}
