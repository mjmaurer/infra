#!/usr/bin/env bash
set -euo pipefail

echo "Listing secret key IDs"
gpg --list-secret-keys --keyid-format=long
echo "\n\n"

echo "Edit the key:"
echo "gpg --expert --edit-key $KEYID"
echo "\n\n"

read -s CERTIFY_PASS
read -s ADMIN_PIN
read KEYID

echo "Then for each subkey run:"
echo "key X (where X is 1,2, or 3)"
echo "keytocard"
echo "save"
# gpg --command-fd=0 --pinentry-mode=loopback --edit-key $KEYID <<EOF
# key 1
# keytocard
# 1
# $CERTIFY_PASS
# $ADMIN_PIN
# save
# EOF
echo "\n\n"

echo "For multiple keys, you must re-import the private subkeys:"
echo "killall gpg-agent"
echo "export GNUPGHOME=$(mktemp -d)"
echo "cd $GNUPGHOME"
echo "gpg --import /path/to/private-subkey-backup.asc"
echo "\nThen run the above commands again"
echo "\n\n"

echo "Make sure the secret key is removed from disk:"
echo "gpg --list-secret-keys"
echo "yubi-switch"
echo "\n\n"

# Could run adduid for more identities
