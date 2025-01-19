{ lib, config, pkgs, ... }:
let
  cfg = config.modules.git;
  email = "mjmaurer777@gmail.com";
in {
  options.modules.git = {
    enable = lib.mkEnableOption "git";

    signingKey = lib.mkOption {
      type = lib.types.str;
      default = "FBEB175D449FFC2B";
      description = "The ID of the gpg signing key to use.";
    };

    credentialStore = lib.mkOption {
      type = lib.types.str;
      default = "";
      description =
        "The gcm credential store to use. Leaving unset automatically uses OS-appropriate store (but doesn't support linux).";
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
        core.excludesfile = "~/.config/git/ignore";
        credential = {
          helper = "manager";
          "https://github.com".username = "mjmaurer";
          credentialStore =
            lib.mkIf (cfg.credentialStore != "") cfg.credentialStore;
        };
        # merge.tool = "vscode";
        # mergetool.vscode.cmd = "code --wait --merge $REMOTE $LOCAL $BASE $MERGED";
        diff.tool = "vscode";
        difftool.vscode.cmd = "$VSCODE --wait --diff $LOCAL $REMOTE";
        push.autoSetupRemote = true;
      };
    };

    programs.ssh = {
      # Prefer explicit identity definitions and IdentitiesOnly to avoid fingerprinting:
      # https://github.com/drduh/YubiKey-Guide?tab=readme-ov-file#copy-public-key
      matchBlocks = {
        "git-auth" = {
          host = "github.com";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_rsa_yubikey.pub";
          # Might just need this on mac:
          # extraOptions = {
          #   "IgnoreUnknown" = "AddKeysToAgent,UseKeychain";
          #   "AddKeysToAgent" = "yes";
          #   "UseKeychain" = "yes";
          # };
        };
      };
    };

    home.file.".config/git/ignore" = {
      text = ''
        .DS_Store
        .direnv/
        .aider*
        .aider.conf.yml
        .aiderignore
      '';
    };
  };
}
