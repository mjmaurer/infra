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
  aiUser = "ai";
  aiGid = 505;
  aiUid = 405;
  otherUser = "other";
  otherGid = 506;
  otherUid = 406;
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
          users = {
            users = {
              ${username} = {
                home = "/Users/${username}";
              };
              ${aiUser} = {
                uid = aiUid;
                gid = aiGid;
                home = "/Users/${aiUser}";
                createHome = true;
                shell = pkgs.zsh;
              };
              # Just for testing. Belongs to no group.
              ${otherUser} = {
                uid = otherUid;
                gid = otherGid;
                home = "/Users/${otherUser}";
                createHome = true;
                shell = pkgs.zsh;
              };
            };
            groups = {
              ${aiUser} = {
                gid = aiGid;
                members = [
                  aiUser
                  username
                ];
              };
            };
            # Only users/groups managed by Darwin:
            knownUsers = [ aiUser otherUser ];
            knownGroups = [ aiUser otherUser ];
          };

          security.sudo.extraConfig = ''
            ${username} ALL=(${aiUser}) NOPASSWD: ALL
            ${username} ALL=(other) NOPASSWD: ALL
          '';

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
              ${aiUser} = {
                # This automatically sets group to users, createHome to true,
                # home to /home/«username», useDefaultShell to true, and isSystemUser to false.
                isNormalUser = true;
                extraGroups = ifTheyExist [
                  "audio"
                ];
                openssh.authorizedKeys.keys = [
                  pubkeys.sshPubYkcWal
                  pubkeys.sshPubYkaStub
                  pubkeys.sshPubYkcKey
                  pubkeys.sshPubBw
                ];
                hashedPasswordFile =
                  if !config.modules.users.minimalInstall then config.sops.secrets.aiHashedPassword.path else null;
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
              {
                users = [ username ];
                commands = [
                  {
                    command = "ALL";
                    options = [ "NOPASSWD" ];
                  }
                ];
                runAs = aiUser;
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
    {
      system.activationScripts.postActivation =
        let
          codeDir = "/opt/code";
        in
        {
          text = ''
            # Create the directory if it doesn't exist
            mkdir -p ${codeDir}

            # Ownership: "system user" owns it. Common choice is root:ai
            chown root:${aiUser} ${codeDir}

            # rwx for owner and group; no access for others.
            # setgid bit (2) makes new files/dirs inherit group "ai".
            /bin/chmod 2770 ${codeDir} 

            # but recommended on macOS: ACL to guarantee group ai has full access
            # even if someone creates files with restrictive umask.
            # (chmod above is usually enough, but ACL makes it more robust.)
            /bin/chmod +a "group:${aiUser} allow read,write,execute,delete,add_file,add_subdirectory,file_inherit,directory_inherit,search,list" ${codeDir} || true
          '';
        };
      environment = {
        systemPackages = [
          (pkgs.writeShellScriptBin "as-${aiUser}" ''
            exec sudo -u ${aiUser} "$@"
          '')
          (pkgs.writeShellScriptBin "be-${aiUser}" ''
            exec sudo -u ${aiUser} -i
          '')
          (pkgs.writeShellScriptBin "be" ''
            #!/usr/bin/env sh
            set -eu

            # The user to become is the first argument.
            USER="''${1:?Usage: $0 <username>}"

            exec sudo -u "$USER" -i
          '')
          (pkgs.writeShellScriptBin "mark-${aiUser}" ''
            #!/usr/bin/env sh
            set -eu

            DIR="''${1:?Usage: $0 /path/to/dir [exclude_glob]}"
            EXCL_GLOB="''${2:-*.env*}"

            # 0) For excluded matches: ONLY ensure "others" cannot read (keep owner/group/mode otherwise)
            # Note: this matches by basename (-name). It will also match directories with ".env" in the name.
            # It does NOT prune; it still traverses into all subdirectories.
            find "$DIR" -name "$EXCL_GLOB" -exec chmod o-r {} +

            # 1) For everything else: group -> ${aiUser}, and owner+group full, others none
            find "$DIR" ! -name "$EXCL_GLOB" -exec chgrp ${aiUser} {} +
            find "$DIR" ! -name "$EXCL_GLOB" -exec chmod u+rwX,g+rwX,o-rwx {} +

            # 2) Ensure future items inherit the group (setgid on directories not excluded)
            find "$DIR" -type d ! -name "$EXCL_GLOB" -exec chmod g+s {} +

            # 3) Defaults for newly created files/dirs under DIR (apply to DIR itself)
            if command -v setfacl >/dev/null 2>&1; then
              # Linux (and macOS if setfacl is installed, e.g. pkgs.acl)
              setfacl -m  g::rwx,o::--- "$DIR"
              setfacl -d -m g::rwx,o::--- "$DIR"
            else
              # macOS built-in ACL tool
              chmod +a "group:${aiUser} allow read,write,execute,file_inherit,directory_inherit,list,search" "$DIR"
              chmod +a "everyone deny read,write,execute,delete,append,writeattr,writeextattr,chown,list,search" "$DIR"
            fi
          '')
        ];
      };
    }
  ];
}
