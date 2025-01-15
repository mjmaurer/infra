echo "Add the following public key to GitHub GPG keys. This enables signing:"
echo "gpg --armor --export mjmaurer777@gmail.com"
echo "\n\n"

echo "Add the Auth subkey's keygrip ID to SOPS (which sets 'service.gpgAgent.sshKeys')"
echo "gpg --list-keys --with-keygrip"
echo "\n\n"

echo "Nix Rebuild"
echo "Confirm that gpg-agent is now managing the SSH key:"
echo "ssh-add -L"
echo "\n\n"

echo "Add the following public key to GitHub SSH keys. This enables auth:"
echo "gpg --export-ssh-key mjmaurer777@gmail.com"
echo "\n\n"

echo "Done!"
