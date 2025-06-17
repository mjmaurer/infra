{
  lib,
  config,
  ...
}:
let
  cfg = config.modules.smbServer;
  boolToString = b: if b then "yes" else "no";
in
{
  options.modules.smbServer = {

    recyclePath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the Samba recycle bin directory where deleted files are stored.";
      example = "/nas/recycle";
    };

    shares = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              path = lib.mkOption {
                type = lib.types.str;
                description = "Absolute path to the directory to be shared.";
              };
              comment = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Optional comment for the share, visible to clients.";
              };
              browseable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether the share is visible in network browse lists.";
              };
              readOnly = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "If true, access to this share is read-only. If false, it's writable (subject to other permissions).";
              };
              guestOk = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "If true, guest access (no password) is allowed for this share.";
              };
              # guestsOk and validUsers are mutually exclusive.
              validUsers = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ "@nas" ];
                description = "List of users and groups (prefix groups with '@') allowed to access this share.";
                example = [
                  "user1"
                  "@editors"
                ];
              };
              forceGroup = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = "nas";
                description = "Force the group ownership of newly created files and directories to this group. Set to null to disable.";
              };
              createMask = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = "02770";
                description = "File creation mode (permissions) for new files, in octal string format. Set to null to use Samba defaults.";
              };
              directoryMask = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = "02770";
                description = "Directory creation mode (permissions) for new directories, in octal string format. Set to null to use Samba defaults.";
              };
            };
          }
        )
      );
      default = { };
      description = "Configuration for individual Samba shares. Each key is the share name.";
    };
  };

  config = {

    # Assert that guestOk and validUsers are not both set for any share
    assertions = lib.flatten (
      lib.mapAttrsToList (
        shareName: shareConfig:
        if shareConfig.guestOk && shareConfig.validUsers != [ ] then
          [
            {
              assertion = false;
              message = "guestOk and validUsers cannot both be set for share ${shareName}";
            }
          ]
        else
          [ ]
      ) cfg.shares
    );

    # Enable Avahi for mDNS (don't need since we're confiuring clients with nixos)
    # might be useful for non-NixOS clients, though.
    # services.avahi = {
    #   enable = true;
    #   nssmdns4 = true;
    #   publish = {
    #     enable = true;
    #     workstation = true;
    #   };
    # };

    services.samba = {
      enable = true;

      settings =
        let
          sambaShareDefinitions = lib.mapAttrs (
            shareName: shareConfig:
            lib.filterAttrs (name: value: value != null) {
              comment = shareConfig.comment;
              path = shareConfig.path;
              browseable = boolToString shareConfig.browseable;
              "read only" = boolToString shareConfig.readOnly;
              "guest ok" = boolToString shareConfig.guestOk;
              "valid users" = lib.concatStringsSep " " shareConfig.validUsers;
              # This might be an alternative for create / directory mask:
              # "inherit permissions" = "yes"; # Inherit permissions from parent directory
              # If 'force user' is unset, Samba will use the user that authenticated.
              "force group" = shareConfig.forceGroup;
              "create mask" = shareConfig.createMask;
              "directory mask" = shareConfig.directoryMask;

              "vfs objects" = [
                "catia"
                "fruit"
                "streams_xattr"
                "recycle"
              ];

            }
          ) cfg.shares;
        in
        {
          global = {
            workgroup = "WORKGROUP"; # Standard default
            "server string" = "%h Samba Server (version: %v, protocol: %R)";
            "netbios name" = config.networking.hostName;
            "server min protocol" = "SMB3";

            # ------------------------------- Performance ------------------------------
            "ea support" = "yes"; # required for xattrs/ADS
            # "aio read size" = 1; # Async IO. Samba should do this automatically
            # "aio write size" = 1; # Async IO
            deadtime = 30; # Close idle connections after 30 minutes

            # --------------------------- macOS compatibility --------------------------
            "fruit:aapl" = "yes";
            # Store everything in an ADS so Windows never sees ._ files
            "fruit:metadata" = "stream";
            "fruit:resource" = "xattr"; # use ADS but avoid the older stream bug
            "fruit:posix_rename" = "yes"; # fixes “replace” operations from Finder
            "fruit:zero_file_id" = "yes"; # avoids duplicate-inode confusion
            "fruit:delete_empty_adfiles" = "yes"; # housekeeping
            # optional tweaks
            "readdir_attr:aapl_max_access" = "no"; # lighter directory listings

            # -------------------------- Recycle bin settings --------------------------
            "recycle:repository" = "${cfg.recyclePath}/%U";
            "recycle:keeptree" = "yes";

            # ----------------------------- Security / Auth ----------------------------
            # "smb encrypt" = "required";
            "hosts allow" = "${config.modules.networking.tailscaleIPRange} 127.0.0.1 localhost";
            # Could also consider limiting interface to tailscale0
            security = "user";
            "guest account" = "nobody";
            "map to guest" = "bad user"; # Users who fail to authenticate are not guests
            "passdb backend" = "tdbsam";
            "obey pam restrictions" = "yes";
            # if yes, keep the password in sync with the user's password
            # "unix password sync" = "yes";
            # "pam password change" = "yes";
            # Default NixOS Samba settings:
            "invalid users" = [ "root" ];
            "passwd program" = "/run/wrappers/bin/passwd %u";

            # --------------------------------- Logging --------------------------------
            logging = "file";
            "log file" = "/var/log/samba/log.%m";
            "max log size" = 1000;

            # -------------------------------- Printers --------------------------------
            "load printers" = "no"; # Disable printer support
            "disable spoolss" = "yes"; # Disable printing support

          };
        }
        // sambaShareDefinitions;
    };
  };
}
