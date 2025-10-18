# ----------------------------- SETUP ----------------------------
# In Finder: Go -> Connect to Server... -> smb://mjmaurer@willow/content
# Save password in Keychain when prompted
# In System Settings -> General -> Login Items, add the share folder to the login picker
# Optional: Manually create 'nas' folder in $HOME and add to Finder favorites (add nas shares under it)
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
  localShareName = "content";
  remoteShareName = "content";

  uid = toString config.modules.users.uid;
  gid = toString config.modules.users.gid;

  # Place to store aliases (manually) to NAS shares added with Finder
  nasShareAliasDir = "${config.users.users.${username}.home}/nas";
  # Finder determines this when shares are manually added, so this is just a hardcode:
  shareMountDir = "/Volumes/";

  # mountScript = pkgs.writeShellScript "smbfs-mount-shares" ''
  #   set -euo pipefail

  #   nasUrl="mjmaurer@$SAMBA_HOST"
  #   contentShareUrl="//$nasUrl/content"

  #   # If already content mounted, exit cleanly
  #   if mount | awk '{print $3}' | grep -Fxq "$contentShareUrl"; then
  #     exit 0
  #   fi

  #   # Mount using Keychain credentials (-N avoids prompting)
  #   /sbin/mount_smbfs -N -o ${mountOpts} "$contentShareUrl" ${nasMountPath} || {
  #     echo "mount_smbfs failed for \"$contentShareUrl\" -> ${nasMountPath}. Make sure your SMB password is saved in your Login Keychain (see module docs)." >&2
  #     exit 1
  #   }
  # '';

  # favoriteOnceScript = pkgs.writeShellScript "add-favorite-smb-once.sh" ''
  #   #!/usr/bin/env bash
  #   set -euo pipefail
  #   URL="smb://${cfg.server}/${cfg.share}"
  #   STAMP="$HOME/Library/Application Support/nix-darwin/.favorite_${cfg.server}_${cfg.share}_added"

  #   # run only once per-user
  #   [[ -e "$STAMP" ]] && exit 0

  #   if [[ -x /usr/bin/sfltool ]]; then
  #     /usr/bin/sfltool add-item -n "${cfg.share} on ${cfg.server}" \
  #       com.apple.LSSharedFileList.FavoriteServers "$URL" || true
  #   else
  #     # fallback: add to Recents so Finder “knows” about it
  #     /usr/bin/open -g "$URL" || true
  #     /bin/sleep 2
  #     /usr/bin/osascript -e 'tell application "Finder" to close every window' || true
  #   fi

  #   /bin/mkdir -p "$(dirname "$STAMP")"
  #   /usr/bin/touch "$STAMP"
  # '';
in
{
  # also: https://support.7fivefive.com/kb/latest/mac-os-smb-client-configuration
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
  # sops.templates.${localShareName} = {
  #   # NOTE -------
  #   # REMEMBER to delete before rebuild for this to work
  #   path = "/etc/auto_${localShareName}";
  #   mode = "0400";
  #   # Could add noatime for performance, but not needed for now
  #   # noperm delegates the actual permissions to the server to
  #   #   avoid client permissions issues.
  #   #   when set, 'dir_mode' and 'file_mode' are mostly just
  #   #   cosmetic for the client.
  #   # i think noperm, dir_mode, file_mode are not supported on server (couldnt mount)
  #   # NOTE: See options with `man mount_smbfs` and `man mount`
  #   content = ''
  #     ${localShareName} -fstype=smbfs,soft,rw,nosuid,noowners ://mjmaurer:${config.sops.placeholder.smbPassword}@${config.sops.placeholder.smbHost}/${remoteShareName}
  #   '';
  # };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "mountshare" ''
      set -euo pipefail
      shareMountPath="${shareMountDir}${remoteShareName}"
      if [[ -d "$shareMountPath" ]]; then
        echo "$shareMountPath exists. Assuming its already mounted."
      else
        # Could enable add_subdirectory in postActivation script if this is annoying (slight risk)
        sudo mkdir -p "$shareMountPath"
        sudo chown ${uid}:${gid} "$shareMountPath"
        smb_pass=$(security find-internet-password -s "willow" -a "mjmaurer" -r "smb " -D "Network Password" -w)
        mount_smbfs //mjmaurer:$smb_pass@willow/content "$shareMountPath"
      fi
    '')
  ];

  system.activationScripts.postActivation = {
    text = ''
      set -euo pipefail

      if [ "$(ls -A ${nasShareAliasDir})" = ".metadata_never_index" ]; then
        echo "----- NOTE ------ ${nasShareAliasDir} is empty. After adding shares in Finder, you may want to move them here for easier access in Finder."
      fi

      # Ensure user mount path exists (for synthetic.conf)
      mkdir -p ${nasShareAliasDir}
      chown ${uid}:${gid} ${nasShareAliasDir}
      chmod 700 ${nasShareAliasDir}
      # Try to disable spotlight indexing on the alias dir (probably does nothing):
      touch ${nasShareAliasDir}/.metadata_never_index

      # Allow user to create subdirs under /Volumes (needed for mountshare script)
      # sudo chmod +a "user:${username} allow add_subdirectory" /Volumes

      # Finder shows mounts under /Volumes, so we need to expose /nas at the root (requires one reboot)
      if ! grep -qE "^nas[[:space:]]" /etc/synthetic.conf 2>/dev/null; then
        printf "nas\tVolumes\n" | tee -a /etc/synthetic.conf

        echo "------ NOTE ------- Added 'nas' to /etc/synthetic.conf. Reboot once for /nas to appear."
      fi
    '';
  };

  # environment = {
  #   systemPackages = [
  #     (pkgs.writeShellScript "smbfs-mount-shares" ''
  #     '')
  #   ];
  # };

  # Per-user LaunchAgent so it can read the user's Login Keychain
  # launchd.user.agents.mountSamba =
  #   let
  #     mountOpts = "soft,rw,nosuid";
  #   in
  #   {
  #     command = "${
  #       pkgs.writeShellApplication {
  #         name = "smbfs-mount-shares";
  #         text = ''
  #           set -euo pipefail

  #           echo "Mounting samba shares to ${nasMountPath}"

  #           nasUrl="mjmaurer@willow"
  #           contentShareUrl="//$nasUrl/content"

  #           # If already content mounted, exit cleanly
  #           if mount | awk '{print $3}' | grep -Fxq "$contentShareUrl"; then
  #             exit 0
  #           fi

  #           contentMntPath="${nasMountPath}/content"
  #           mkdir -p $contentMntPath
  #           chown ${uid}:${gid} $contentMntPath

  #           # Mount using Keychain credentials (-N avoids prompting)
  #           /sbin/mount_smbfs -N -o ${mountOpts} "$contentShareUrl" $contentMntPath || {
  #             echo "mount_smbfs failed for \"$contentShareUrl\" -> ${nasMountPath}. Make sure your SMB password is saved in your Login Keychain (see module docs)." >&2
  #             exit 1
  #           }
  #         '';
  #       }
  #     }/bin/smbfs-mount-shares";
  #     serviceConfig = {
  #       Label = "mountSamba";
  #       RunAtLoad = true;

  #       # Re-run when the network (re)appears; mount_smbfs returns immediately
  #       # Might not work
  #       # KeepAlive = {
  #       #   NetworkState = true;
  #       # };

  #       # Avoid tight loops if it fails repeatedly
  #       ThrottleInterval = 30;
  #       StartInterval = 600; # try every 10 minutes

  #       # Agent should run in GUI sessions
  #       # LimitLoadToSessionType = "Aqua";

  #       StandardOutPath = "/tmp/mount-samba.log";
  #       StandardErrorPath = "/tmp/mount-samba.err";

  #       # EnvironmentFile = config.sops.templates."mountSecrets".path;
  #     };
  #   };

  # launchd.user.agents."nas.favorite" = lib.mkIf cfg.addToFinderFavorites {
  #   enable = true;
  #   serviceConfig = {
  #     ProgramArguments = [ "${favoriteOnceScript}" ];
  #     RunAtLoad = true;
  #     KeepAlive = false;
  #     StandardOutPath = "/tmp/nas-favorite.log";
  #     StandardErrorPath = "/tmp/nas-favorite.err";
  #   };
  # };

  sops = {
    templates = {
      "mountSecrets" = {
        owner = username;
        content = ''
          SAMBA_HOST=${config.sops.placeholder.smbHost}
        '';
        # reloadUnits = [ "mountSamba.user" ];
      };
    };
  };

  # NOTE: The below requires reboot to take effect
  # system.activationScripts.postActivation.text = lib.mkOrder 1600 ''
  #   /usr/bin/install -d -o ${username} -g ${gid} -m 700 "${cfg.nasMountPath}"

  #   # Disable spotlight indexing on the nas mount (can be slow and annoying)
  #   # mdutil -i off ${cfg.nasMountPath} || true

  #   # /etc/auto_master already exists, so we append to it
  #   if ! grep -q "auto_${localShareName}" /etc/auto_master; then
  #     echo "${cfg.nasMountPath} auto_${localShareName} -nosuid" >> /etc/auto_master
  #     echo "Added auto master entry for ${cfg.nasMountPath}." >&2
  #     echo "Can add to finder with Cmd+Shift+G and type ${cfg.nasMountPath}" >&2
  #   fi

  #   # likely only darwin needs this
  #   # expose /nas at the root (requires one reboot)
  #   if ! grep -qE '^nas($|\s)' /etc/synthetic.conf 2>/dev/null; then
  #     echo "nas" >> /etc/synthetic.conf
  #     echo "Added 'nas' to /etc/synthetic.conf. Reboot once for /nas to appear."
  #   fi

  #   # Ensure autofs is aware of any changes to maps or master config
  #   if command -v automount >/dev/null 2>&1; then
  #     automount -vc
  #   else
  #     echo "automount command not found, skipping autofs reload." >&2
  #   fi
  # '';
}
