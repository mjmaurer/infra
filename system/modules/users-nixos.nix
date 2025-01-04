{ pkgs, config, lib, ... }:
{
  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;
    users = {
      root.passwordFile = config.sops.secrets.rootPassword.path;
      mjmaurer = {
        isNormalUser = true;
        extraGroups = [ "wheel" "audio" "video" "sway" "plugdev" "networkmanager" ];
        passwordFile = config.sops.secrets.mjmaurerPassword.path;
      };
    };
  };
}
