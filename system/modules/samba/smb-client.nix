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
  localVolume = "/Volumes/nas";
  localShareName = "main";
  remoteShareName = "personal-main";
in
{
  options.modules.smbClient = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable SMB client module.";
    };

    smbMountPath = lib.mkOption {
      type = lib.types.str;
      default = if pkgs.stdenv.isDarwin then "/Volumes/nas/personal" else "/nas/personal";
      description = "Absolute mount path for personal SMB share.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [

      (
        if isDarwin then
          # also: https://support.7fivefive.com/kb/latest/mac-os-smb-client-configuration
          {
            # Can run `smbutil statshares -a` to see current shares (and confirm status like SIGNING)
            sops.templates."nsmb.conf" = {
              owner = "root";
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

                [${config.sops.placeholder.smbHost}:mjmaurer]
                password="${config.sops.placeholder.smbPassword}
              '';
            };

            environment.etc.${localShareName}.text = ''
              ${localShareName} \
                  -fstype=smbfs,soft,noatime,nosuid,rw ://mjmaurer@${builtins.readFile config.sops.secrets.smbHost.path}/${remoteShareName}
            '';
            environment.etc.auto_master.text = ''
              +auto_master
              ${localVolume} /etc/${localShareName} -nosuid
            '';

            launchd.daemons.autofs-reload = {
              serviceConfig.Label = "dev.autofs-reload";
              serviceConfig.ProgramArguments = [
                "/usr/sbin/automount"
                "-cv"
              ];
              serviceConfig.RunAtLoad = true;
              requires = [
                "etc-${localShareName}"
                "etc-auto_master"
                "template-nsmb_conf"
              ];
            };
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
