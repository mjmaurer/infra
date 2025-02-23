#!/usr/bin/env bash
set -euo pipefail
# To run when configuring a new (headed) machine
# These host keys can only be read by root

# Create temporary directory with restricted permissions
temp_dir=$(mktemp -d -t ssh_host_keys.XXXXXX)
chmod 700 "$temp_dir"

echo "Generating new host SSH key pair (requires sudo)"
# Equivalent to `ssh-keygen -A`, but for just one key type (ED25519)
# Host keys aren't encrypted / don't need a passphrase
sudo ssh-keygen -N "" -t ed25519 -f "$temp_dir/ssh_host_ed25519_key"

echo "Converting SSH host public key to age format."
echo "Add this to '.sops.yaml' for the new host and run 'sops updatekeys ...' for each relevant secrets yaml file:"
sudo cat "$temp_dir/ssh_host_ed25519_key.pub" | ssh-to-age

# Default backup location with timestamp
backup_location="/etc/ssh/host-keys-$(date +%Y%m%d-%H%M%S)"
echo "Backup location [default: $backup_location]: "
read -r input_location
if [ -n "$input_location" ]; then
    backup_location="$input_location"
fi

mkdir -p "$backup_location"
sudo mv "$temp_dir/ssh_host_ed25519_key" "$backup_location/"
sudo mv "$temp_dir/ssh_host_ed25519_key.pub" "$backup_location/"

# Cleanup
rm -rf "$temp_dir"

echo "SSH keys backed up to $backup_location and deleted"
echo "After updating sops, you can run 'sopsa -k $backup_location/ssh_host_ed25519_key --verbose /path/to/secrets.yaml' to test it (might need gpg unplugged)."
 