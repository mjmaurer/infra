{ pkgs, config, lib, isDarwin, derivationName, username, ... }:
let
  isNixOS = !isDarwin;
in
lib.mkMerge [
  (lib.optionalAttrs isNixOS {
    users = {
      mutableUsers = false;
      defaultUserShell = pkgs.zsh;
      users = {
        root.passwordFile = config.sops.secrets.rootPassword.path;
        ${username} = {
          isNormalUser = true;
          extraGroups = [ "wheel" "audio" "video" "sway" "plugdev" "networkmanager" ];
          passwordFile = config.sops.secrets.mjmaurerPassword.path;
        };
      };
    };
  })
  (lib.optionalAttrs isDarwin {
    # Even though Darwin doesn't manage users, we still need to register
    # the already-created user for the home-manager module to work.
    users.users.${username} = {
      home = "/Users/${username}";
    };
  })
]
