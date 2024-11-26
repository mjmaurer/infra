{ config, pkgs, lib, ... }:
{
  # imports = lib.pipe ../modules [
  #   builtins.readDir
  #   (lib.filterAttrs (name: _: lib.hasSuffix ".nix" name))
  #   (lib.mapAttrsToList (name: _: ./services + "/${name}"))
  # ];

  imports = [
    ./shell/common-shell.nix

    ../modules/alacritty/alacritty.nix
    ../modules/continuedev/continuedev.nix
    ../modules/obsidian/obsidian.nix
    ../modules/zsh/zsh.nix
    ../modules/bash/bash.nix
    ../modules/duplicacy/duplicacy.nix
    ../modules/tmux/tmux.nix
    ../modules/aerospace/aerospace.nix
    ../modules/aider/aider.nix
    ../modules/neovim/neovim.nix
    ../modules/aichat/aichat.nix
  ];

  modules = {
    zsh.enable = true;
    bash.enable = true;
    tmux.enable = true;
    aider.enable = true;
    aichat.enable = true;
    neovim.enable = true;
    alacritty.enable = true;
    continuedev = {
      enable = true;
      justConfig = true;
    };


  };

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  xdg = {
    # Sets up XDG_DATA_HOME, XDG_CONFIG_HOME, XDG_CACHE_HOME, etc.
    enable = true;
  };

  home =
    {
      username = "mjmaurer";
      stateVersion = "22.05";
      file = {
        ".config/nix/nix.conf" = {
          text = ''
            # Enable flakes
            experimental-features = nix-command flakes
          '';
        };
      };
      packages = with pkgs; [
        # Fonts
        meslo-lgs-nf

        # Nix
        nil
        nixpkgs-fmt
        nix-prefetch-git
        nix-search-cli
        nixfmt
        vulnix

        # Git
        git-lfs
        gh

        # Other
        ripgrep
        rclone
        glow
        yt-dlp
        gdown
        bat
        htop
        jq
        fd
        tree
        devenv
        wget
        neofetch
        unzip
        speedtest-cli
        p7zip
        thefuck
      ];
    };

  programs = {
    fzf = {
      enable = true;
      enableBashIntegration = true;
      # I think this conflicts with zsh fzf-tab:
      # enableZshIntegration = true;
    };
    dircolors = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
    git = {
      enable = true;
      userName = "Michael Maurer";
      package = pkgs.gitFull;
      userEmail = "mjmaurer777@gmail.com";
      aliases = {
        pr = "pull --rebase";
        gc = "commit -v";
        gcs = "commit -v --gpg-sign";
        ga = "add --all";
        s = "status";
        dt = "difftool -y";
      };
      signing = {
        key = "DA7297EEEF7B429CE7B4A11EE5DDBB38668F1E46";
        signByDefault = false;
      };
      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "nvim";
        credential.helper = "store";
        # merge.tool = "vscode";
        # mergetool.vscode.cmd = "code --wait --merge $REMOTE $LOCAL $BASE $MERGED";
        diff.tool = "vscode";
        difftool.vscode.cmd = "$VSCODE --wait --diff $LOCAL $REMOTE";
      };
    };
  };

  services.gpg-agent = {
    enable = lib.mkDefault true;
    defaultCacheTtl = 1800;
  };
}
