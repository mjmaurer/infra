{
  lib,
  config,
  pkgs,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.git;
  email = "mjmaurer777@gmail.com";
in
{
  options.modules.git = {
    enable = lib.mkEnableOption "git";

    signingKey = lib.mkOption {
      type = lib.types.str;
      default = "791D2FBA6E8C2722";
      description = "The ID of the gpg signing key to use.";
    };

    credentialStore = lib.mkOption {
      type = lib.types.str;
      default = if pkgs.stdenv.isLinux then "cache" else "";
      description = "The gcm credential store to use. Leaving unset automatically uses OS-appropriate store (but doesn't support linux).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Another option is https://github.com/hickford/git-credential-oauth
    # Just using latest because build was breaking on Darwin with 25.11 stable
    # https://github.com/NixOS/nixpkgs/issues/479348 
    home.packages = [ pkgs-latest.git-credential-manager ];

    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      signing = {
        key = cfg.signingKey;
        signByDefault = cfg.signingKey != "";
      };
      settings = {
        user = {
          name = "Michael Maurer";
          email = email;
        };
        alias = {
          diffall = "git add --intent-to-add . && git --no-pager diff && git reset";
          dap = "git add --intent-to-add . && git diff && git reset";
          da = "diffall";
          pr = "pull --rebase";
          gc = "commit -v";
          gcs = "commit -v --gpg-sign";
          ga = "add --all";
          s = "status";
          dt = "difftool -y";
        };
        init.defaultBranch = "main";
        core.editor = "nvim";
        core.excludesfile = "~/.config/git/ignore";
        credential = {
          helper = "manager";
          guiPrompt = !pkgs.stdenv.isLinux;
          cacheOptions = "--timeout 86400";
          credentialStore = lib.mkIf (cfg.credentialStore != "") cfg.credentialStore;
          "https://github.com".username = "mjmaurer";
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
        .devdata/
        .claude
        CLAUDE.md 
      '';
    };

    home.activation.cloneInfra = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "$HOME/infra/.git" ]; then
        echo "Cloning infra..."
        ${pkgs.git}/bin/git clone https://github.com/mjmaurer/infra.git "$HOME/infra"
      fi
    '';
  };
}
