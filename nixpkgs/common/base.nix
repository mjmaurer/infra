{ config, pkgs, lib, ... }:
{
  # imports = lib.pipe ../modules [
  #   builtins.readDir
  #   (lib.filterAttrs (name: _: lib.hasSuffix ".nix" name))
  #   (lib.mapAttrsToList (name: _: ./services + "/${name}"))
  # ];

  imports = [
    ./common-shell.nix

    ../modules/zsh/zsh.nix
    ../modules/bash/bash.nix
    ../modules/duplicacy/duplicacy.nix
    ../modules/obsidian/obsidian.nix
    ../modules/tmux/tmux.nix
    ../modules/aerospace/aerospace.nix
    ../modules/aider/aider.nix
  ];

  modules = {
    zsh.enable = true;
    bash.enable = true;
    tmux.enable = true;
    aider.enable = true;
  };

  programs.home-manager.enable = true;

  home.username = "mjmaurer";
  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    nil
    nixpkgs-fmt
    ripgrep
    rclone
    vulnix
    yt-dlp
    gdown
    nixfmt
    bat
    htop
    devenv
    wget
    neofetch
    unzip
    speedtest-cli
    nix-prefetch-git
    git-lfs
    gh
    p7zip
    thefuck
  ];

  home.file = {
    ".continue/config.json" = {
      source = ../config/continuedev/config.json;
    };
    ".continue/config.ts" = {
      source = ../config/continuedev/config.ts;
    };
    ".config/nix/nix.conf" = {
      text = ''
        # Enable flakes
        experimental-features = nix-command flakes
      '';
    };
  };

  services.gpg-agent = {
    enable = lib.mkDefault true;
    defaultCacheTtl = 1800;
  };

  programs = {
    fzf = {
      enable = true;
      enableBashIntegration = true;
      # I think this conflicts with zsh fzf-tab:
      # enableZshIntegration = true;
    };
    neovim = {
      enable = true;
      vimAlias = true;
      extraConfig = builtins.readFile ../config/vim/config.vim;
      plugins = with pkgs.vimPlugins; [ vim-polyglot ];
    };
    dircolors = {
      enable = true;
      enableBashIntegration = true;
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
      };
      signing = {
        key = "DA7297EEEF7B429CE7B4A11EE5DDBB38668F1E46";
        signByDefault = false;
      };
      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "nvim";
        credential.helper = "store";
      };
    };
  };
}
