# General way of importing an SSH key into GPG
# Could maybe do this with nix / activation scripts

# https://github.com/drduh/YubiKey-Guide?tab=readme-ov-file#import-ssh-keys
ssh-add ~/.ssh/id_rsa && rm ~/.ssh/id_rsa