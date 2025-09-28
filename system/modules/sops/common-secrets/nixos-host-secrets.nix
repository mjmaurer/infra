{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.host-secrets;
  hostSopsFile = ../vault/nixos-host.yaml;
in
{
  options.modules.host-secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "linux"
      ];
    };
  };
  config = lib.mkIf cfg.enable {
    sops.secrets = {
      mjmaurerHashedPassword = {
        neededForUsers = true;
        # Allow for this to be overridden by the user
        sopsFile = lib.mkDefault hostSopsFile;
      };
    };
  };
}
