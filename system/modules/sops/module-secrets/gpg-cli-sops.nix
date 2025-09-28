{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.gpg-cli-sops;
in
{

  options.modules.gpg-cli-sops = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
      ];
    };
  };
  config = lib.mkIf cfg.enableGpgSops {
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
    };
  };
}
