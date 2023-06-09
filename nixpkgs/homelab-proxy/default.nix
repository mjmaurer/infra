{ config, pkgs, ... }:

let
  domain = "howell.haus";
in
{
  imports = [ ../common.nix ../common-linux.nix ];

  home.username = pkgs.lib.mkForce "ubuntu";

  # home.packages = with pkgs; [
  # ];

  programs.bash.sessionVariables = {
    MACHINE_NAME = "homelab-proxy";
    # See docker-compose for most environment variables needed 
    # MAKE SURE TO ADD THEM THERE TOO
    DOMAIN = domain;
    # VOUCH_DOMAINS = domain; not need for allUIsers
    VOUCH_DOCUMENT_ROOT = "/vp_in_a_path";
    VOUCH_COOKIE_DOMAIN = domain;
    OAUTH_CALLBACK_URL = "https://${domain}/vp_in_a_path/auth";
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
