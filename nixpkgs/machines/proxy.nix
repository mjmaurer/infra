{ config, pkgs, ... }:

{
  imports = [ ../common/linux.nix ];

  home.username = pkgs.lib.mkForce "ubuntu";

  modules.commonShell = {
    machineName = "proxy";
    sessionVariables = {
      WIN_DOWNLOADS = "/mnt/c/Users/mjmau/Downloads/";
    };
    initExtra = ''
      whitelist_user () {
        env_var_name="VOUCH_WHITELIST"
        term="$1"

        if [ -z "''${!env_var_name}" ]; then
            export ''${env_var_name}="''${term}"
        else
            export ''${env_var_name}="''${!env_var_name},''${term}"
        fi
        echo "Make sure to reload vouch"
      }
      source_env () {
        export $(grep -v '^#' .env | xargs)
      }
    '';
  };
}
