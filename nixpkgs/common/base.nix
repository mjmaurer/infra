{ config, pkgs, lib, ... }:
{
  # imports = lib.pipe ../modules [
  #   builtins.readDir
  #   (lib.filterAttrs (name: _: lib.hasSuffix ".nix" name))
  #   (lib.mapAttrsToList (name: _: ./services + "/${name}"))
  # ];

  imports = [
    ./common-shell.nix

    ../modules/continuedev/continuedev.nix
    ../modules/obsidian/obsidian.nix
    ../modules/zsh/zsh.nix
    ../modules/bash/bash.nix
    ../modules/duplicacy/duplicacy.nix
    ../modules/tmux/tmux.nix
    ../modules/aerospace/aerospace.nix
    ../modules/aider/aider.nix
    ../modules/neovim/neovim.nix
  ];

  modules = {
    zsh.enable = true;
    bash.enable = true;
    tmux.enable = true;
    aider.enable = true;
    neovim.enable = true;
    continuedev = {
      enable = true;
      justConfig = true;
    };
  };

  programs.home-manager.enable = true;

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
        jq
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

  services.gpg-agent = {
    enable = lib.mkDefault true;
    defaultCacheTtl = 1800;
  };
}
