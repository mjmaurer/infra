{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.smb-secrets;
  smbSopsFile = ../vault/smb.yaml;
in
{
  options.modules.smb-secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
        "dev-client"
        "nas-access"
      ];
    };
  };
  config = lib.mkIf cfg.enable {
    sops.secrets = {
      smbHost = {
        sopsFile = smbSopsFile;
      };
      smbPassword = {
        sopsFile = smbSopsFile;
      };
    };
  };
}
