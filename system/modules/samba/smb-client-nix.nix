{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.smb-client-nix;

  shareName = "content";
  mountRoot = "/nas";
  mountPoint = "${mountRoot}/${shareName}";

  # Use declared UID helper (kept consistent across the repo)
  uid = toString config.modules.users.uid;
  nasGroup = config.users.groups.nas.name;
in
{
  options.modules.smb-client-nix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "nas-access"
      ];
      description = "Enable NixOS SMB client mounting for the NAS content share.";
    };
  };

  config = lib.mkIf cfg.enable ({
    assertions = [
      {
        assertion = pkgs.stdenv.isLinux;
        message = "modules.smb-client-nix is intended for NixOS (Linux) systems.";
      }
    ];

    # Ensure CIFS support is available
    boot.supportedFilesystems = [ "cifs" ];

    # Ensure mount directories exist and have correct ownership/permissions
    systemd.tmpfiles.settings."smb-client-nix" = {
      ${mountRoot}.d = {
        user = "root";
        group = nasGroup;
        # setgid bit so new files/dirs inherit nas-clients group
        mode = "2770";
      };
      ${mountPoint}.d = {
        user = "root";
        group = nasGroup;
        mode = "2770";
      };
    };

    sops.templates."smb-credentials" = {
      path = "/run/secrets/smb-credentials";
      mode = "0400";
      content = ''
        username=mjmaurer
        password=${config.sops.placeholder.smbPassword}
      '';
    };

    # Mount the NAS content share with systemd automount
    fileSystems.${mountPoint} = {
      device = "//willow/${shareName}";
      fsType = "cifs";
      options = [
        "credentials=${config.sops.templates."smb-credentials".path}"
        "uid=${uid}"
        "gid=${nasGroup}"
        "file_mode=0660"
        "dir_mode=0770"
        # Behavior
        "rw"
        "vers=3.0"
        "iocharset=utf8"
        "_netdev"
        # Mount on first access; unmount after idle period
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
        "nofail"
      ];
    };
  });
}
