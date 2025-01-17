echo "========= Nix Requirements ==========\n"

echo "Make sure the SIGN subkey ID is configured in home-manager for `git.signingKey`:\n"
echo "Add the AUTH subkey's keygrip ID to SOPS (which sets gpg-agent's sshcontrol):\n"
gpg --list-keys --with-keygrip
echo "\n\n"

echo "Nix Rebuild (`nrb`)"
echo "\n\n"

echo "========= GitHub Requirements ==========\n"

echo "Confirm that gpg-agent is now managing the SSH key. Get the public with either:"
echo "ssh-add -L"
echo "or"
echo "gpg --export-ssh-key mjmaurer777@gmail.com"
echo "And then add it to GitHub SSH keys."
echo "\n\n"
# This also depends on the `addGpgSshIdentity` activation, which sets ~/.ssh/id_rsa_yubikey.pub.

echo "Add the following public key to GitHub GPG keys. This enables signing:\n"
gpg --armor --export mjmaurer777@gmail.com
echo "\n\n"

echo "Test auth with:"
echo "ssh -T git@github.com"
echo "Test signing with a commit"
echo "\n\n"

echo "Done!"
