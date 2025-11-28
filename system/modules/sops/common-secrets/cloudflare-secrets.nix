{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.cloudflare-secrets;
  hostSopsFile = ../vault/cloudflare.yaml;
in
{
  options.modules.cloudflare-secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "cloudflare"
      ];
    };
  };
  config = lib.mkIf cfg.enable {
    sops.secrets = {
      cloudflareDnsApiToken = {
        sopsFile = ../vault/cloudflare.yaml;
      };
    };
  };
}
