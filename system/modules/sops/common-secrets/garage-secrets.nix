{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.garage-secrets;
  garageSopsFile = ../vault/garage.yaml;
in
{
  options.modules.garage-secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "garage"
      ];
    };
  };
  config = lib.mkIf cfg.enable {
    sops = {
      templates = {
        "garage.env" = {
          content = ''
            GARAGE_ADMIN_TOKEN=${config.sops.placeholder.garageAdminToken}
            GARAGE_METRICS_TOKEN=${config.sops.placeholder.garageMetricsToken}
            GARAGE_RPC_SECRET=${config.sops.placeholder.garageRpcSecret}

          '';
          # Newlines in 'content' are needed!
        };
      };
      secrets = {
        garageRpcSecret = {
          sopsFile = garageSopsFile;
        };
        garageAdminToken = {
          sopsFile = garageSopsFile;
        };
        garageMetricsToken = {
          sopsFile = garageSopsFile;
        };
      };
    };
  };
}
