{ config, pkgs, ... }:

{
  imports = [ ../common/common.nix ../common/common-linux.nix ];

  home.username = pkgs.lib.mkForce "ubuntu";

  programs.bash.sessionVariables = {
    MACHINE_NAME = "proxy";
  };

  programs.bash.initExtra = ''
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

}
