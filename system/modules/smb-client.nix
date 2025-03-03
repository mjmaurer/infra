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
  userHomeCfg = config.users.users.${username};
  darwinMountScript =
    if isDarwin then
      ''
        # Return early if already mounted
        if mount | grep -q "${cfg.smbMountPath}"; then
          exit 0
        fi

        mkdir -p ${cfg.smbMountPath}
        chown ${username}:staff ${cfg.smbMountPath}
        # Only allow user to access the mount point
        chmod 700 ${cfg.smbMountPath}

        # mkdir -p "${cfg.smbMountPath}-ro"

        SMB_HOST=$(cat ${config.sops.secrets.smbHost.path})
        SMB_URL=$(cat ${config.sops.secrets.smbUrl.path})

        # Everyday share 
        SMB_MAIN_SHARE="$SMB_URL/personal-main"
        # Read-only / top-level share
        # SMB_SHARE_URI="$SMB_URL/personal"

        # Only wait on ping for max .5 second
        if ping -c 1 -t 500 "$SMB_HOST" >/dev/null 2>&1; then
          # Check if mount path exists and is empty, remove if so
          if [ -d "${cfg.smbMountPath}" ] && [ -z "$(ls -A ${cfg.smbMountPath})" ]; then
            echo "empty mount path may cause mount_smbfs error"
            # rmdir "${cfg.smbMountPath}"
            # mkdir -p ${cfg.smbMountPath}
          fi
          # Run as user to avoid permission issues
          if ! su ${username} -c "mount_smbfs $SMB_MAIN_SHARE ${cfg.smbMountPath}"; then
            echo "Failed to mount SMB share"
            exit 1
          fi
        else
          echo "Could not reach SMB host. Are you connected to tailscale?"
        fi
      ''
    else
      '''';
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

      (lib.mkIf (pkgs.stdenv.isLinux) { })

      (lib.mkIf (isDarwin)
        # consider multichannel: https://support.apple.com/en-us/102010
        # also: https://support.7fivefive.com/kb/latest/mac-os-smb-client-configuration
        {
          environment.etc."nsmb.conf".text = ''
            [default]
            # https://support.apple.com/en-gb/101442
            signing_required=no
            # Use NTFS streams if supported
            streams=yes

            # https://gist.github.com/jbfriedrich/49b186473486ac72c4fe194af01288be
            aapl_off=false
          '';
          # Need mkOrder because sops-nix installs secrets using mkAfter (1500 priority)
          system.activationScripts.postActivation.text = lib.mkOrder 1600 darwinMountScript;
          launchd.daemons = lib.mkOrder 1600 {
            smb-mount = {
              command = "sh -c ${lib.escapeShellArg darwinMountScript}";
              serviceConfig = {
                RunAtLoad = true;
                KeepAlive = false;
              };
            };
          };
        }
      )
    ]
  );
}
