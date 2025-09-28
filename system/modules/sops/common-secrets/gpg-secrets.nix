{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.gpg-secrets;
  gpgSopsFile = ../vault/gpg.yaml;
in
{

  options.modules.gpg-secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
      ];
    };
  };
  config = lib.mkIf cfg.enable {
    sops = {
      templates = {
        "gpg_sshcontrol" = {
          owner = config.users.users.${username}.name;
          content = ''
            ${config.sops.placeholder.gpgAuthKeygrip}

          '';
          # Newlines in 'content' are needed!
        };
      };
      secrets = {
        gpgAuthKeygrip = {
          owner = config.users.users.${username}.name;
          path = "${config.users.users.home}/.gnupg/sshcontrol";
          mode = "0444";
          sopsFile = gpgSopsFile;
        };
        gpgPublicKey = {
          owner = config.users.users.${username}.name;
          path = "${config.users.users.home}/.gnupg/pubkey.asc";
          mode = "0444";
          sopsFile = gpgSopsFile;
        };
      };
    };
  };
}
