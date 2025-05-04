{
  lib,
  pkgs,
  ...
}:
let
  cleanup-script = pkgs.writeScript "cleanup-temp" ''
    if [ -d "$NEW_HOST_DATA" ]; then
      echo "Cleaning up temporary directory: $NEW_HOST_DATA"
      rm -rf "$NEW_HOST_DATA"
    fi
  '';
  ssh-host-bootstrap = pkgs.writeScriptBin "ssh-host-bootstrap" (
    builtins.readFile ../pkgs/crypt/ssh-host-bootstrap.sh
  );
in
(pkgs.mkShell {
  name = "new-host-shell";

  packages = [
    ssh-host-bootstrap
  ];

  shellHook = ''
    echo "Entering shell for new host setup"

    # Register cleanup on shell exit
    trap "$(cat ${cleanup-script})" EXIT

    NEW_HOST_DATA=$(mktemp -d -t new_host.XXXXXX)
    NEW_HOST_SSH="$NEW_HOST_DATA/ssh_host_keys"
    NEW_HOST_LUKS="$NEW_HOST_DATA/luks_keys"

    mkdir -p "$NEW_HOST_SSH"

    # Prompt for initrd SSH host keys
    read -p "[Only needed for NixOS] Do you want to setup initrd SSH host keys? (y/n): " INITRD_CHOICE
    INITRD_GEN=""
    if [[ "$INITRD_CHOICE" == "y" || "$INITRD_CHOICE" == "Y" ]]; then
      INITRD_GEN="true"
    fi
    # Prompt for luks keys 
    read -p "[Only needed for NixOS] Do you want to provide a luks disk ecryption key? (y/n): " LUKS_CHOICE
    LUKS_GEN=""
    if [[ "$LUKS_CHOICE" == "y" || "$LUKS_CHOICE" == "Y" ]]; then
      mkdir -p "$NEW_HOST_LUKS"
      LUKS_GEN="true"
    fi

    echo -e "\n\n----------------- Creating an SSH host key for the new host: ------------------\n\n"
    ssh-host-bootstrap -t $NEW_HOST_SSH -s $BACKUP_ARGS

    if [[ -n "$INITRD_GEN" ]]; then
      echo -e "\n\n------------------ Creating an SSH host key for initrd: ----------------\n\n"
      ssh-host-bootstrap -t $NEW_HOST_SSH -i /nix/secret/initrd
    fi

    if [[ -n "$LUKS_GEN" ]]; then
      echo -e "\n\n------------------ Creating a disk encryption key file: -----------------\n\n"
      
      # Loop until passwords match
      while true; do
        echo "Please enter a passphrase for disk encryption (will not be echoed):"
        read -s DISK_PASSPHRASE
        echo "Please confirm the passphrase:"
        read -s DISK_PASSPHRASE_CONFIRM
        
        if [[ "$DISK_PASSPHRASE" == "$DISK_PASSPHRASE_CONFIRM" ]]; then
          break
        else
          echo "Error: Passphrases do not match. Please try again."
        fi
      done
      
      # Write the passphrase to the key file
      echo "$DISK_PASSPHRASE" > "$NEW_HOST_LUKS/disk.key"
      echo "Disk encryption key created at $NEW_HOST_LUKS/disk.key"
    fi

    # Prompt for backup directory
    read -p "Do you want to backup the new host data directory? (y/n): " BACKUP_CHOICE
    BACKUP_ARGS=""
    if [[ "$BACKUP_CHOICE" == "y" || "$BACKUP_CHOICE" == "Y" ]]; then
      read -p "Enter backup directory path: " BACKUP_DIR
      if [[ -d "$BACKUP_DIR" ]]; then
        if [[ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
          echo "Warning: Backup directory is not empty."
          read -p "Continue anyway? (y/n): " CONTINUE
          if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
            echo "Aborting."
            exit 1
          fi
        fi
        BACKUP_ARGS="-b $BACKUP_DIR"
      else
        echo "Backup directory does not exist. Creating it."
        mkdir -p "$BACKUP_DIR"
        BACKUP_ARGS="-b $BACKUP_DIR"
      fi
    fi

    # Copy the generated files to the backup directory if specified
    if [[ -n "$BACKUP_ARGS" && -n "$BACKUP_DIR" ]]; then
      echo "Copying generated files to backup directory..."
      sudo cp -rp "$NEW_HOST_DATA/." "$BACKUP_DIR/"
      echo "Files copied to $BACKUP_DIR with original permissions preserved."
    fi

    echo -e "\n\n--------------------------- Completed ------------------------------\n\n"
    echo "Files are located at NEW_HOST_DATA ($NEW_HOST_DATA)"
    echo "ls \$NEW_HOST_DATA"
    if [[ -n "$BACKUP_ARGS" && -n "$LUKS_GEN" ]]; then
      echo "Run the following outside this shell to prepare for nixos-anywhere:"
      echo "export NEW_HOST_DATA=$BACKUP_DIR"
    fi
    echo -e "\n\033[0;31mPlease read through the output and make sure to follow any additional steps (i.e. for SOPS)\033[0m"

    echo -e "\n\033[0;31m---- LEAVING THIS SHELL WILL DESTROY THE NEW DIRECTORY ------\033[0m\n"

  '';
})
// {
  meta = with lib; {
    licenses = licenses.mit;
    platforms = platforms.all;
  };
}
