#!/usr/bin/env bash
set -euo pipefail

# These host keys can only be read by root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run with sudo privileges."
    echo "Usage: sudo $0 -t <temp_dir> [-b <backup_dir>]"
    exit 1
fi

# Usage information
usage() {
    echo "Usage: $0 -t <temp_dir> [-b <backup_dir>] [-s]"
    echo "Example: $0 -t /tmp/ssh_keys -b /secure/host-keys-backup -s"
    echo "Options:"
    echo "  -t <temp_dir>    Temporary directory for key generation"
    echo "  -b <backup_dir>  Optional backup directory"
    echo "  -s               Show SOPS/age key output. Useful if you're creating a host key for a new machine."
    exit 1
}

# Parse command line arguments
temp_dir=""
backup_dir=""
show_sops=0

while getopts "t:b:hs" opt; do
    case ${opt} in
        t)
            temp_dir=$OPTARG
            ;;
        b)
            backup_dir=$OPTARG
            ;;
        s)
            show_sops=1
            ;;
        h)
            usage
            ;;
        \?)
            usage
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$temp_dir" ]; then
    echo "Error: Temporary directory is required"
    usage
fi

# Ensure temp_dir exists and has proper permissions
if [ ! -d "$temp_dir" ]; then
    echo "Error: Temporary directory does not exist: $temp_dir"
    exit 1
fi

install_path="/etc/ssh"

# Check if the install path already exists in temp_dir
if [ -d "$temp_dir$install_path" ]; then
    echo "Error: Path already exists in temporary directory: $temp_dir$install_path"
    echo "Please use a different temporary directory or remove the existing path."
    exit 1
fi

# Only check backup_dir if it was provided
if [ -n "$backup_dir" ] && [ -d "$backup_dir$install_path" ]; then
    echo "Error: Path already exists in backup directory: $backup_dir$install_path"
    echo "Please use a different backup directory or remove the existing path."
    exit 1
fi

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp_dir$install_path"

echo "Generating new host SSH key pair (requires sudo)"
# Equivalent to `ssh-keygen -A`, but for just one key type (ED25519)
# Host keys aren't encrypted / don't need a passphrase
ssh-keygen -N "" -t ed25519 -f "$temp_dir$install_path/ssh_host_ed25519_key"

# Extra careful for private key:
chmod 600 "$temp_dir$install_path/ssh_host_ed25519_key"
echo "SSH created in $temp_dir$install_path"

if [ "$show_sops" -eq 1 ]; then
    echo "Converting SSH host public key to age format."
    echo "If this is for a new host's /etc/ssh (not it's initrd):"
    echo "Add this to '.sops.yaml' for the new host and run 'sops updatekeys ...' for each relevant secrets yaml file:"
    echo "After updating sops, you can run 'sopsa -k $temp_dir$install_path/ssh_host_ed25519_key --verbose /path/to/secrets.yaml' to test it."
    echo ""
    < "$temp_dir$install_path/ssh_host_ed25519_key.pub" ssh-to-age
    echo ""
fi

# Only backup if a backup directory was specified
if [ -n "$backup_dir" ]; then
    mkdir -p "$backup_dir$install_path"
    cp -rp "$temp_dir$install_path" "$backup_dir$install_path"
    echo "SSH keys backed up to $backup_dir$install_path"
fi
