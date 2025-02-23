#!/usr/bin/env bash
set -euo pipefail
# To run when configuring a new (headed) machine
# These host keys can only be read by root

echo "Generating new host SSH key pair (requires sudo)"
# Equivalent to `ssh-keygen -A`, but for just one key type (ED25519)
# Host keys aren't encrypted / don't need a passphrase
sudo ssh-keygen -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key

echo "Converting SSH host public key to age format."
echo "Add this to `.sops.yaml` for the new host:"
sudo cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age

sops updatekeys 

# TODO: use this instead to avoid temp file:
# read -s SSH_TO_AGE_PASSPHRASE; export SSH_TO_AGE_PASSPHRASE
# Need to unencrypt the key to convert it to age 
# cp ./id_ed25519 /tmp/id_ed25519
# ssh-keygen -p -N "" -f /tmp/id_ed25519
# mkdir -p ~/.config/sops/age
# echo "Converting SSH key to age key store at: ~/.config/sops/age/keys.txt"
# ssh-to-age -private-key -i /tmp/id_ed25519 > ~/.config/sops/age/keys.txt
# rm /tmp/id_ed25519

echo "Where would you like to backup the SSH key pair?"
read -r backup_location
mkdir -p "$backup_location"

echo "Backing up SSH key pair to $backup_location"
mv ./id_ed25519 "$backup_location/"
mv ./id_ed25519.pub "$backup_location/"
rm ./id_ed25519
rm ./id_ed25519.pub

echo "SSH keys backed up to $backup_location"
echo "Age public key saved as ./age.pub"
