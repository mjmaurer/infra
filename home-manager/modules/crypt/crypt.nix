# Includes SSH, GPG, and Yubikey

# ------------------------- THERE BE DRAGONS HERE ------------------------
# Whether due to GPG or some config buried in home-manager,
# this module is extremely flakey.
# To avoid pain and suffering:
# - NEVER change the GPG homedir away from the default
# - After any changes:
#   - Run `gpgrestart`
#   - Run `gpg --card-status` then try to ssh into a NixOS host
# - You can't get gpg to listen to a custom socket path, don't even try.
{
  osConfig ? null,
  lib,
  config,
  isDarwin,
  nixosHostnames,
  pkgs,
  ...
}:
let
  cfg = config.modules.crypt;
  gpgHomedir = "${config.home.homeDirectory}/.gnupg"; # Default. DONT CHANGE THIS.

  # GPG has no way to configure the socket path, so we have to use the default.
  # This would probably cause issues if we ever wanted to use a Yubikey locally on a remote host,
  # but it might be as easy as starting gpg-agent manually (although its disabled in nix by default)
  gpgForwardedSocket = "/run/user/1000/gnupg/S.gpg-agent";
in
{
  options.modules.crypt = {
    remoteHost = lib.mkOption {
      type = lib.types.bool;
      default = !isDarwin;
      description = ''
        If true, the host is primarily accessed remotely,
        and so gpg-agent won't create a local socket and 
        gpg-agent won't start automatically.

        Also, SSH will not be configured with the nixos hosts.
      '';
    };
  };

  config = lib.mkMerge [
    {
      home.packages = [
        # These are to get a stable path for the `opensc-pkcs11.so` and `libykcs11.dylib` files (see PIV setup in README).
        # At ~/.nix-profile/lib/opensc-pkcs11.so
        pkgs.opensc
        # At ~/.nix-profile/lib/libykcs11.dylib
        pkgs.yubico-piv-tool

        pkgs.yubikey-personalization
        pkgs.yubikey-manager

        (pkgs.writeShellScriptBin "yubi-switch" ''
          echo "\nIf ERR: run 'gpg --import gpg.pub' to import the public key\n"
          gpg-connect-agent "scd serialno" "learn --force" /bye 

          # Alternative:

          # KEYGRIPS=$(gpg --with-keygrip --list-secret-keys mjmaurer777@gmail.com | awk '/Keygrip/ { print $3 }')
          # for keygrip in $KEYGRIPS
          # do
          #     rm "$HOME/.gnupg/private-keys-v1.d/$keygrip.key" 2> /dev/null
          # done
        '')
      ];

      modules.commonShell.shellAliases = {
        "ybs" = "yubi-switch";
        "gpgr" = "gpg-connect-agent reloadagent /bye";
        "gpgrestart" = "gpgconf --kill gpg-agent && gpg-connect-agent /bye";
      };

      programs = {
        gpg = {
          enable = true;
          homedir = gpgHomedir;
          publicKeys = lib.mkIf (osConfig ? sops) [
            # Enabled / available for all
            { source = osConfig.sops.secrets.gpgPublicKey.path; }
          ];
          # TODO: consider mutableKeys = false;
          settings = import ./gpg.conf.nix {
            remoteHost = cfg.remoteHost;
          };
          scdaemonSettings = {
            # reader-port = "Yubico Yubikey";
            # log-file = "/tmp/gpg-scdaemon.log";

            # The following get scdaemon and pcscd to play nicely together.
            # https://ludovicrousseau.blogspot.com/2019/06/gnupg-and-pcsc-conflicts.html
            # This can be removed probably
            # scdaemon's piv implementation can conflict with pcke's when sshing
            # But it doesn't matter because I couldn't get it to work without ykman list anway
            disable-application = "piv";
            # Also possibly needed for forwarding yubikey over ssh (see ssh-match.conf.nix)
            # Unforutnately, these break PIN caching: https://dev.gnupg.org/T5436
            disable-ccid = true; # Tell scdaemon to not use the CCID driver (only pcscd)
            # pcsc-shared = true; # Allow other processes to use the smartcard
          };
        };
        ssh = {
          enable = true;
          includes = [
            # For manual/local configurations
            "~/.ssh/config.local"
          ];
          matchBlocks = import ./ssh-match.conf.nix {
            inherit
              nixosHostnames
              pkgs
              gpgHomedir
              gpgForwardedSocket
              ;
          };
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
            enable = !cfg.remoteHost;

            # make S.gpg-agent.extra for forwarding
            enableExtraSocket = true;

            defaultCacheTtl = cacheTtl;
            defaultCacheTtlSsh = cacheTtl;
            maxCacheTtl = maxCacheTtl;
            maxCacheTtlSsh = maxCacheTtl;
            enableZshIntegration = true;
            # Prefer gpg-agent over ssh-agent
            enableSshSupport = true;
            # Smartcard support. This talks to pcscd (enabled in system crypt modules):
            enableScDaemon = true;

            # Shared card for ssh forwarding breaks pin caching: https://dev.gnupg.org/T5436
            pinentry.package = pkgs.pinentry-curses;
            # pinentry.package = lib.mkIf (!isDarwin) pkgs.pinentry-curses;
            # extraConfig = lib.mkIf (isDarwin) ''
            #  pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
            # '';
          };
      };
      # GPG keys (by keygrip ID) to expose via SSH
      # Replaces gpg-agent's `sshKeys` option
      home.file."${gpgHomedir}/sshcontrol" =
        lib.mkIf (osConfig ? sops && builtins.hasAttr "gpg_sshcontrol" osConfig.sops.templates)
          {
            source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates.gpg_sshcontrol.path;
          };
      home.sessionVariablesExtra = (
        lib.optionalString (config.services.gpg-agent.enableSshSupport) ''
          if [[ -z "''${SSH_AUTH_SOCK}" ]] || [[ "''${SSH_AUTH_SOCK}" =~ '^/private/tmp/com\.apple\.launchd\.[^/]+/Listeners$' ]]; then
            export SSH_AUTH_SOCK="$(${config.programs.gpg.package}/bin/gpgconf --list-dirs agent-ssh-socket)"
          fi
        ''
      );
      home.activation.addGpgSshIdentity = lib.hm.dag.entryAfter [ "activateServices" ] ''
        run mkdir -p "$HOME/.ssh"
        # DISABLED: This was bringing up an extra gpg-agent
        # Ensure gpg-agent is aware of the smartcard BEFORE exporting
        # if ! ${config.programs.gpg.package}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye >/dev/null 2>&1; then
        #    echo "Warning: gpg-connect-agent learn command failed. Export might fail."
        # fi

        # Export SSH public key from GPG
        run export _YBPK="$(${config.programs.gpg.package}/bin/gpg --homedir ${gpgHomedir} --export-ssh-key mjmaurer777@gmail.com 2>/tmp/gpg_export_error.log)"
        if [ -n "$_YBPK" ]; then
          # Can test with 'ssh git@github.com'
          run echo "$_YBPK" > "$HOME/.ssh/id_rsa_yubikey.pub"
          run chmod 600 ~/.ssh/id_rsa_yubikey.pub
        else
          run echo "No GPG SSH key could be exported"
          run echo "Check /tmp/gpg_export_error.log for details from gpg command." >&2
          run echo "Try running 'gpgrestart'"
          run echo "It's possible that ssh-agent is interfering with gpg-agent. See 'home-manager/.../crypt.nix'"
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
    }
  ];
}
