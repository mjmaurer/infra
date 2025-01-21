#!/usr/bin/env bash
set -euo pipefail

echo "run 'gpg --import gpg.pub' to import the public key"
gpg-connect-agent "scd serialno" "learn --force" /bye 


# Alternative:

# KEYGRIPS=$(gpg --with-keygrip --list-secret-keys mjmaurer777@gmail.com | awk '/Keygrip/ { print $3 }')
# for keygrip in $KEYGRIPS
# do
#     rm "$HOME/.gnupg/private-keys-v1.d/$keygrip.key" 2> /dev/null
# done

# # gpgconf --kill gpg-agent
# gpg --card-status