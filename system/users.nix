{ pkgs, config, ... }:
{
  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;
    users = {
      root.passwordFile = config.sops.secrets.rootPassword.path;
      mjmaurer = {
        isNormalUser = true;
        # wheel is sufficient for sudo privileges
        extraGroups = [ "wheel" "audio" "video" "sway" "plugdev" "networkmanager" ];
        passwordFile = config.sops.secrets.mjmaurerPassword.path;
      };
    };
  };
}
