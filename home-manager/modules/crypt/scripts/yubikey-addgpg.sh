#!/usr/bin/env bash
set -euo pipefail

echo "Listing secret key IDs"
gpg --list-secret-keys --keyid-format=long
echo "\n\n"

echo "Edit the key:"
echo "gpg --expert --edit-key $KEY_ID"
echo "\n\n"

echo "Then for each subkey run:"
echo "key X (where X is 1,2, or 3)"
echo "keytocard"
echo "save"
echo "\n\n"

echo "For multiple keys, you must re-import the main certify key:"
echo "killall gpg-agent"
echo "export GNUPGHOME=$(mktemp -d)"
echo "cd $GNUPGHOME"
echo "gpg --import /path/to/private-key-backup.asc"
echo "\nThen run the above commands again"
echo "\n\n"

echo "Make sure the secret key is removed from disk:"
echo "gpg --delete-secret-keys $KEY_ID"
echo "\n\n"

# Could run adduid for more identities
