#!/usr/bin/env bash
set -euo pipefail

echo "This script will help configure your Yubikey for GPG operations"
echo "Please ensure your Yubikey is inserted"
echo ""

# Check if yubikey is inserted
if ! ykman info >/dev/null 2>&1; then
    echo "No Yubikey detected! Please insert your Yubikey and try again"
    exit 1
fi

# FIDO U2F, FIDO2
echo "First, let's change the admin FIDO PIN"
echo "Choose a secure alphanumeric PIN of 8 or more characters"
ykman fido access change-pin

echo "Change the admin PIV (PUK) PIN (Default: 12345678)"
echo "Choose a secure PIN of 8 or more digits"
ykman piv access change-puk

echo "Change the user PIV PIN (Default: 123456)"
echo "Choose a secure PIN of 6 or more digits"
ykman piv access change-pin

echo "Change the admin OpenPGP PIN (Default: 12345678)"
echo "Choose a secure PIN of 8 or more digits"
ykman openpgp access change-admin-pin

echo "Change the user OpenPGP PIN (Default: 123456)"
echo "Choose a secure PIN of 6 or more digits"
ykman openpgp access change-pin

echo "Setting the number of retries for the OpenPGP PIN to 8"
ykman openpgp access set-retries 8 8 8 -f

echo "Setting the touch policy for the OpenPGP PIN"
ykman openpgp keys set-touch sig off
ykman openpgp keys set-touch aut on
ykman openpgp keys set-touch enc on

# echo "Reducing the chance of accidental OTP output"
# ykman otp settings 1 --touch long

# # Configure touch policies
# echo -e "\nConfiguring touch policies for PIV operations..."
# echo "You'll need to enter the admin PIN"

# # Require touch for authentication
# ykman piv certificates generate-key 9a --algorithm ECCP256 --pin-policy ONCE --touch-policy ALWAYS pubkey.pem

# # Require touch for signing
# ykman piv certificates generate-key 9c --algorithm ECCP256 --pin-policy ONCE --touch-policy ALWAYS pubkey.pem

# # Require touch for key management
# ykman piv certificates generate-key 9d --algorithm ECCP256 --pin-policy ONCE --touch-policy ALWAYS pubkey.pem

# # Require touch for card authentication
# ykman piv certificates generate-key 9e --algorithm ECCP256 --pin-policy ONCE --touch-policy ALWAYS pubkey.pem

# Clean up temporary file
# rm pubkey.pem

echo "Done!"
