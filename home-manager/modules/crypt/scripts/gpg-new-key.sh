# ---------------------------------------------------------------------------- #
#                                    Create                                    #
# ---------------------------------------------------------------------------- #

killall gpg-agent

EXISTING_GPGHOME=$GNUPGHOME
# Create a temporary directory for GPG operations
export GNUPGHOME=$(mktemp -d -t gnupg-$(date +%Y-%m-%d)-XXXXXXX)

echo "Running in $GNUPGHOME"

cd $GNUPGHOME
cp $EXISTING_GPGHOME/gpg.conf .
cp $EXISTING_GPGHOME/gpg-agent.conf .
# gpgr


echo "Enter passphrase for the key: "
read -s CERTIFY_PASS
echo "Confirm passphrase: "
read -s CERTIFY_PASS_CONFIRM

if [ "$CERTIFY_PASS" != "$CERTIFY_PASS_CONFIRM" ]; then
  echo "Passphrases do not match!"
  exit 1
fi
echo "Enter a comment for the key: "
read COMMENT
echo "Enter subkey expiration date (e.g. yyyy-mm-dd): "
read SUBKEY_EXPIRATION

export KEY_TYPE=rsa4096
export IDENTITY="Michael Maurer ($COMMENT) <mjmaurer777@gmail.com>"

echo "Generating cert key..."
echo "$CERTIFY_PASS" | gpg --batch --passphrase-fd 0 \
    --quick-generate-key "$IDENTITY" "$KEY_TYPE" cert never

export KEYID=$(gpg -k --with-colons "$IDENTITY" | awk -F: '/^pub:/ { print $5; exit }')
export KEYFP=$(gpg -k --with-colons "$IDENTITY" | awk -F: '/^fpr:/ { print $10; exit }')
printf "\nKey ID: %40s\nKey FP: %40s\n\n" "$KEYID" "$KEYFP"

for SUBKEY in sign encrypt auth ; do \
  echo "$CERTIFY_PASS" | gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
      --quick-add-key "$KEYFP" "$KEY_TYPE" "$SUBKEY" "$SUBKEY_EXPIRATION"
done

echo "Done creating! Key info:"
gpg -K

# ---------------------------------------------------------------------------- #
#                                    Backup                                    #
# ---------------------------------------------------------------------------- #

BACKUP_DIR=$GNUPGHOME/backups
mkdir -p $BACKUP_DIR
echo "Backing up key to './backups'..."
echo "$CERTIFY_PASS" | gpg --output $BACKUP_DIR/$KEYID-private-certify.key \
    --batch --pinentry-mode=loopback --passphrase-fd 0 \
    --armor --export-secret-keys $KEYID

echo "$CERTIFY_PASS" | gpg --output $BACKUP_DIR/$KEYID-private-subkeys.key \
    --batch --pinentry-mode=loopback --passphrase-fd 0 \
    --armor --export-secret-subkeys $KEYID

echo "$CERTIFY_PASS" | gpg --batch --pinentry-mode=loopback \
    --passphrase-fd 0 --export-ownertrust > $BACKUP_DIR/$KEYID-ownertrust.txt

echo "Select '1'"
echo "$CERTIFY_PASS" | gpg --output $BACKUP_DIR/$KEYID-revocation.asc \
    --pinentry-mode=loopback --passphrase-fd 0 \
    --armor --gen-revoke $KEYID

gpg --output $BACKUP_DIR/$KEYID-public.asc \
    --armor --export $KEYID

gpg --list-keys > $BACKUP_DIR/$KEYID-list-keys.txt

echo "Done! Delete $GNUPGHOME and `exec zsh` after backing up"
echo "You could now run `yubi-conf` and `yubi-addgpg` to configure and add the key to the Yubikey"