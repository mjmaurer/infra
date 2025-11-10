{
  pkgs,
  pubkeys,
  config,
  lib,
  isDarwin,
  derivationName,
  username,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{

  options.modules.users = {
    minimalInstall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable SOPS-managed user setup for minimal installs.";
    };
    uid = lib.mkOption {
      type = lib.types.int;
      default = if pkgs.stdenv.isDarwin then 502 else config.users.users.${username}.uid;
    };
    gid = lib.mkOption {
      type = lib.types.int;
      default = if pkgs.stdenv.isDarwin then 20 else config.users.users.${username}.gid;
    };
  };

  config = lib.mkMerge [
    (
      if isDarwin then
        {
          # Even though Darwin doesn't manage users, we still need to register
          # the already-created user for the home-manager module to work.
          users.users.${username} = {
            home = "/Users/${username}";
          };

          # On Darwin, macos manages the user and group IDs, but we can
          # still verify that they match our expectations.
          system.activationScripts.preActivation.text = ''
            set -euo pipefail
            actual_uid=$(/usr/bin/id -u ${username})
            actual_gid=$(/usr/bin/id -g ${username})

            echo "User ${username} has UID $actual_uid and GID $actual_gid"

            if [ "$actual_uid" != "${toString config.modules.users.uid}" ]; then
              echo "ERROR: UID mismatch for ${username}: expected ${toString config.modules.users.uid}, got $actual_uid" >&2
              exit 1
            fi

            if [ "$actual_gid" != "${toString config.modules.users.gid}" ]; then
              echo "ERROR: GID mismatch for ${username}: expected ${toString config.modules.users.gid}, got $actual_gid" >&2
              exit 1
            fi
          '';
        }
      else
        {
          # NixOS
          users = {
            mutableUsers = false;
            defaultUserShell = pkgs.zsh;
            # I believe not declaring a root user is equivalent to disabling root login:
            # https://wiki.archlinux.org/title/Sudo#Disable_root_login
            users = {
              ${username} = {
                # This automatically sets group to users, createHome to true,
                # home to /home/«username», useDefaultShell to true, and isSystemUser to false.
                isNormalUser = true;
                extraGroups = ifTheyExist [
                  "wheel"
                  "audio"
                  "video"
                  "render"
                  "sway"
                  "plugdev"
                  "networkmanager"
                  "docker"
                ];
                openssh.authorizedKeys.keys = [
                  pubkeys.sshPubYkcWal
                  pubkeys.sshPubYkaStub
                  pubkeys.sshPubYkcKey
                  pubkeys.sshPubBw
                ];
                hashedPasswordFile =
                  if !config.modules.users.minimalInstall then
                    config.sops.secrets.mjmaurerHashedPassword.path
                  else
                    null;
              };
            };
          };
          security.sudo = {
            # If we're doing a quick minimal install, don't require password for sudo
            wheelNeedsPassword = !config.modules.users.minimalInstall;
            enable = true;
            extraRules = [
              {
                # 'wheel' users will be able to suspend, reboot, and poweroff without a password
                commands = [
                  {
                    command = "${pkgs.systemd}/bin/systemctl suspend";
                    options = [ "NOPASSWD" ];
                  }
                  {
                    command = "${pkgs.systemd}/bin/reboot";
                    options = [ "NOPASSWD" ];
                  }
                  {
                    command = "${pkgs.systemd}/bin/poweroff";
                    options = [ "NOPASSWD" ];
                  }
                ];
                groups = [ "wheel" ];
              }
            ];
            # extraConfig = with pkgs; ''
            #   Defaults:picloud secure_path="${lib.makeBinPath [
            #     systemd
            #   ]}:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
            # '';
          };
        }
    )
  ];
}
