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
    home.packages = [
      pkgs-latest.git-credential-manager

      (pkgs.writeShellScriptBin "sharedClone" ''
        # Run git clone with all arguments
        out="$(${pkgs.git}/bin/git clone --config core.sharedRepository=0770  "$@" 2>&1)"
        status=$?

        # Re-emit output so it behaves like normal git clone
        printf '%s\n' "$out"

        [ "$status" -eq 0 ] || exit "$status"

        # Extract destination directory from:  Cloning into 'DIR'...
        dest="$(printf '%s\n' "$out" | sed -n "s/^Cloning into '\\(.*\\)'\\.\\{3\\}$/\\1/p" | tail -n 1)"

        # Fallback: if output parsing fails (rare), do best-effort from first non-option
        if [ -z "$dest" ]; then
          url=""
          for a in "$@"; do
            case "$a" in
              -*) ;;
              *) url="$a"; break ;;
            esac
          done
          base="$(basename "$url")"
          dest="''${base%.git}"
        fi

        if [ -d "''$dest" ]; then
          echo "Applying group permissions to ''$dest..."
          chmod -R u=rwX,g=rwX,o= "''$dest"
          find "''$dest" -type d -exec chmod g+s {} +
        else
          echo "Directory ''$dest does not exist after clone."
        fi 
      '')
    ];

    modules.commonShell.shellAliases = {
      sclone = "sharedClone";
    };

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
