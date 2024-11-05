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

  # Reload system units when changing configs
  systemd.user.startServices = "sd-switch";

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
      username = lib.mkDefault "mjmaurer";
      homeDirectory = lib.mkDefault "/home/${config.home.username}";
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

        nil
        nixpkgs-fmt
        ripgrep
        rclone
        vulnix
        yt-dlp
        gdown
        nixfmt
        bat
        fd
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
        tldr
      ];
    };

  programs = {
    htop.enable = true;
    jq.enable = true;
    # zathura.enable = true;
    lsd = {
      enable = true;
      enableAliases = true;
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
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
      };
      signing = {
        key = "DA7297EEEF7B429CE7B4A11EE5DDBB38668F1E46";
        signByDefault = false;
      };
      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "nvim";
        credential.helper = "store";
        pull.rebase = "false";
        alias.merge = "merge --no-edit"; # no editor popup on merge
        push.autoSetupRemote = "true";
      };
    };
  };

  services.gpg-agent = {
    enable = lib.mkDefault true;
    defaultCacheTtl = 1800;
  };
}
