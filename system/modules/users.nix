{ pkgs, pubkeys, config, lib, isDarwin, derivationName, username, ... }:
let
  isNixOS = !isDarwin;
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in lib.mkMerge [
  (lib.optionalAttrs isNixOS {
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
          hashedPasswordFile = config.sops.secrets.mjmaurerHashedPassword.path;
        };
      };
    };
  })
  (lib.optionalAttrs isDarwin {
    # Even though Darwin doesn't manage users, we still need to register
    # the already-created user for the home-manager module to work.
    users.users.${username} = { home = "/Users/${username}"; };
  })
]
