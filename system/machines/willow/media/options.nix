{ lib, config, ... }:
let
  cfg = config.modules.mediaStack;
in
{
  options.modules.mediaStack = {
    enableContainers = lib.mkEnableOption "Media services";

    umask = lib.mkOption {
      type = lib.types.str;
      description = "Umask for all media services.";
      # 'others' have no access, 'group' has rwx, 'user' has rwx
      default = "0007";
    };

    groups = lib.mkOption {
      type = lib.types.submodule {
        options = {
          general = lib.mkOption {
            type = lib.types.str;
            description = "Group for all media service users.";
          };
        };
      };
      default = {
        general = "media";
      };
    };

    ports = lib.mkOption {
      type = lib.types.submodule {
        options = {
          qbitWeb = lib.mkOption {
            type = lib.types.str;
          };
          qbitWebNginx = lib.mkOption {
            type = lib.types.str;
          };
          sab8118 = lib.mkOption {
            type = lib.types.str;
          };
          sabWeb = lib.mkOption {
            type = lib.types.str;
          };
          sabWebNginx = lib.mkOption {
            type = lib.types.str;
          };
          plexWeb = lib.mkOption {
            type = lib.types.str;
          };
        };
      };
      default = {
        qbitWeb = "50080";
        sabWeb = "60080";
        sab8118 = "9118"; # Otherwise conflicts with qbit
        plexWeb = "32400";
      };
    };
  };
}
