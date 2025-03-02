#!/usr/bin/env bash
set -euo pipefail

# Usage information
usage() {
    echo "Usage: $0 -t <temp_dir> [-b <backup_dir>] [-i <install_path>] [-s]"
    echo "Example: $0 -t /tmp/ssh_keys -b /secure/host-keys-backup -i /etc/ssh -s"
    echo "Options:"
    echo "  -t <temp_dir>    Temporary directory for key generation"
    echo "  -b <backup_dir>  Optional backup directory"
    echo "  -i <install_path> Path where SSH keys should be installed (default: /etc/ssh)"
    echo "  -s               Show SOPS/age key output. Useful if you're creating a host key for a new machine."
    exit 1
}

# Parse command line arguments
temp_dir=""
backup_dir=""
show_sops=0
install_path=""

while getopts "t:b:i:hs" opt; do
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
        i)
            install_path=$OPTARG
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

# Set default installation path if not specified via command line
if [ -z "$install_path" ]; then
    install_path="/etc/ssh"
fi

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
sudo ssh-keygen -N "" -t ed25519 -f "$temp_dir$install_path/ssh_host_ed25519_key"

# Extra careful for private key:
sudo chmod 600 "$temp_dir$install_path/ssh_host_ed25519_key"
echo "SSH created in $temp_dir$install_path"

if [ "$show_sops" -eq 1 ]; then
    echo "\n==== SOPS ====\n"
    echo "Converting SSH host public key to age format."
    echo "Add this to '.sops.yaml' for the new host and run 'sops updatekeys ...' for each relevant secrets yaml file:"
    echo ""
    < "$temp_dir$install_path/ssh_host_ed25519_key.pub" ssh-to-age
    echo ""
    echo "After updating sops, you can run 'sopsa -k $temp_dir$install_path/ssh_host_ed25519_key --verbose /path/to/secrets.yaml' to test it."
fi

# Only backup if a backup directory was specified
if [ -n "$backup_dir" ]; then
    mkdir -p "$backup_dir$install_path"
    cp -rp "$temp_dir$install_path" "$backup_dir$install_path"
    echo "SSH keys backed up to $backup_dir$install_path"
fi
