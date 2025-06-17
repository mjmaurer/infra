{
  username,
  lib,
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
      default = false;
      description = "Enable SMB client module.";
    };

    nasMountPath = lib.mkOption {
      type = lib.types.str;
      default = if pkgs.stdenv.isDarwin then "/Volumes/nas" else "/nas";
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
                # protocol_vers_map=4 # Hopefully use SMB 3.0 by default. Might cause issues

                # Disable multi-channel support (users reported speed issues) 
                mc_on=no

                # https://gist.github.com/jbfriedrich/49b186473486ac72c4fe194af01288be
                aapl_off=false

                [${config.sops.placeholder.smbHost}:mjmaurer]
                password="${config.sops.placeholder.smbPassword}"
              '';
            };
            sops.templates.${localShareName} = {
              path = "/etc/auto_${localShareName}";
              content = ''
                ${localShareName} \
                  -fstype=smbfs,soft,noatime,nosuid,rw \
                  ://mjmaurer@${config.sops.placeholder.smbHost}/${remoteShareName}
              '';
            };

            system.activationScripts.postActivation.text = lib.mkOrder 1600 ''
              # /etc/auto_master already exists, so we append to it
              if ! grep -q "^${cfg.nasMountPath} " /etc/auto_master; then
                echo "${cfg.nasMountPath} ${
                  config.sops.templates.${localShareName}.path
                } -nosuid" >> /etc/auto_master
                echo "Added auto master entry for ${cfg.nasMountPath}." >&2
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
