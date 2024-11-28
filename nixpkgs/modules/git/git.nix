{ lib, config, pkgs, ... }:
let
  cfg = config.modules.git;
  email = "mjmaurer777@gmail.com";
in
{
  options.modules.git = {
    enable = lib.mkEnableOption "git";

    signingKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The gpg signing key to use.";
    };

    credentialStore = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The gcm credential store to use. Leaving unset automatically uses OS-appropriate store (but doesn't support linux).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Another option is https://github.com/hickford/git-credential-oauth
    home.packages = [ pkgs.git-credential-manager ];

    programs.git = {
      enable = true;
      userName = "Michael Maurer";
      package = pkgs.gitFull;
      userEmail = email;
      aliases = {
        pr = "pull --rebase";
        gc = "commit -v";
        gcs = "commit -v --gpg-sign";
        ga = "add --all";
        s = "status";
        dt = "difftool -y";
      };
      signing = {
        key = cfg.signingKey;
        signByDefault = cfg.signingKey != "";
      };
      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "nvim";
        credential = {
          helper = "manager";
          "https://github.com".username = "mjmaurer";
        } // lib.optionalAttrs (cfg.credentialStore != "") {
          # Only set credentialStore if it's actually set
          credentialStore = cfg.credentialStore;
        };
        # merge.tool = "vscode";
        # mergetool.vscode.cmd = "code --wait --merge $REMOTE $LOCAL $BASE $MERGED";
        diff.tool = "vscode";
        difftool.vscode.cmd = "$VSCODE --wait --diff $LOCAL $REMOTE";
        push.autoSetupRemote = true;
      };
    };

    programs.ssh = {
      matchBlocks = {
        "git-auth" = {
          host = "github.com";
          identityFile = "~/.ssh/id_ed25519_gitauth";
          # Might just need this on mac:
          extraOptions = {
            "AddKeysToAgent" = "yes";
            "UseKeychain" = "yes";
          };
        };
      };
    };

    # Just demonstrating how to create 
    home.file.".local/bin/setup-git-ssh-keys" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        
        SSH_KEY="$HOME/.ssh/id_ed25519_gitauth"
        
        # Check if keys already exist
        if [[ -f "$SSH_KEY" ]]; then
          echo "SSH key already exists at $SSH_KEY"
          exit 1
        fi
        
        # Create .ssh directory if it doesn't exist
        mkdir -p "$HOME/.ssh"
        
        # Generate SSH key for auth
        ssh-keygen -t ed25519 -f "$SSH_KEY" -C "${email}"
        echo "Additional config needed on Mac:"
        echo "https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent"
        echo "Might just need this on mac as per above:"
        echo 'eval "$(ssh-agent -s)"'
        echo "ssh-add --apple-use-keychain ~/.ssh/id_ed25519_gitauth"
        echo "And then add key to github: https://github.com/settings/keys"
        
        # Generate gpg key for signing (interactive)
        gpg --full-generate-key

        echo "Enter the ID following 'sec ed25519/' into git.signingKey"
        echo "You can find this with 'gpg --list-secret-keys --keyid-format=long'"
        
        # Set correct permissions
        chmod 600 "$SSH_KEY"
        chmod 644 "$SSH_KEY.pub"
        
        echo "SSH keys generated successfully!"
        echo "Authentication public key:"
        cat "$SSH_KEY.pub"
      '';
    };

  };
}
