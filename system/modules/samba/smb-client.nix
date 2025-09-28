# ----------------------------- TROUBLESHOOTING ----------------------------
# First, check if tailscale is up for any error
# Next, try umount + automount
# Then, try deleting the auto_content line from auto_master and rebuild
{
  username,
  lib,
  mylib,
  config,
  isDarwin,
  pkgs,
  ...
}:
let
  cfg = config.modules.smbClient;
  localShareName = "content";
  remoteShareName = "content";
in
{
  options.modules.smbClient = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
      ];
      description = "Enable SMB client module.";
    };

    nasMountPath = lib.mkOption {
      type = lib.types.str;
      default = if pkgs.stdenv.isDarwin then "/nas" else "/nas";
      description = "Absolute mount path for shares to be mounted under on the local filesystem.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [

      (
        if isDarwin then
          # also: https://support.7fivefive.com/kb/latest/mac-os-smb-client-configuration
          {
            # Can run `smbutil statshares -a` to see current shares (and confirm status like SIGNING)
            sops.templates."nsmb_conf" = {
              path = "/etc/nsmb.conf";
              mode = "0400";
              content = ''
                [default]
                # https://support.apple.com/en-gb/101442
                signing_required=no
                # Use NTFS streams if supported
                streams=yes
                dir_cache_off=yes
                dir_cache_max_cnt=0
                # port445=np_netbios
                notify_off=yes
                protocol_vers_map=4 # Hopefully use SMB 3.0 by default. Might cause issues

                # Disable multi-channel support (users reported speed issues) 
                mc_on=no

                # https://gist.github.com/jbfriedrich/49b186473486ac72c4fe194af01288be
                aapl_off=false
              '';
            };
            sops.templates.${localShareName} = {
              path = "/etc/auto_${localShareName}";
              mode = "0400";
              # Could add noatime for performance, but not needed for now
              content = ''
                ${cfg.nasMountPath}/${localShareName} -fstype=smbfs,soft,rw,nosuid ://mjmaurer:${config.sops.placeholder.smbPassword}@${config.sops.placeholder.smbHost}/${remoteShareName}
              '';
            };

            system.activationScripts.postActivation.text = lib.mkOrder 1600 ''
              # /etc/auto_master already exists, so we append to it
              if ! grep -q "auto_${localShareName}" /etc/auto_master; then
                echo "/- auto_${localShareName} -nosuid" >> /etc/auto_master
                echo "Added auto master entry for ${cfg.nasMountPath}." >&2
                echo "Can add to finder with Cmd+Shift+G and type ${cfg.nasMountPath}" >&2
              fi
              # Ensure autofs is aware of any changes to maps or master config
              if command -v automount >/dev/null 2>&1; then
                automount -vc
              else
                echo "automount command not found, skipping autofs reload." >&2
              fi
            '';
          }
        else
          # NixOS
          {
            # Placeholder for NixOS specific SMB client config if ever needed
          }
      )
    ]
  );
}
