{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.postgresql-secrets;
  postgresqlSopsFile = ../vault/postgresql.yaml;
in
{
  options.modules.postgresql-secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "postgresql"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        postgresPassword = {
          sopsFile = postgresqlSopsFile;
        };
      };
    };
  };
}
