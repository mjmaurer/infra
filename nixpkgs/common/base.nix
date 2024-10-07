{ config, pkgs, lib, ... }:
let
  sharedShell = {
    env = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BOBBY_PORT = 7850;
      AUTOMATIC_PORT = 7860;
      RVC_PORT = 7865;
      PLEX_WEB_PORT = 32400;
      JELLYFIN_WEB_PORT = 8096;

    };
    aliases = {
      ".." = "cd ..";
      "gc" = "git commit -v";
      "gcs" = "git commit -v --gpg-sign";
      "ga" = "git add --all";
      "gs" = "git status";
      "rg" = "rg --hidden";
      "nix-shell" = "nix-shell --command 'zsh'";
      "ns" = "nix-shell";
      "la" = lib.mkDefault "ls -A --color";
      "ls" = lib.mkDefault "ls --color";
      "hmswitchnoload" = "home-manager -f ~/.config/nixpkgs/machines/$MACHINE_NAME.nix switch -b backup";
      "dtail" = "docker logs -tf --tail='50'";
      "dstop" = "docker stop `docker ps -aq`";
      "dlog" = "docker logs ";
      "dtop" = "docker run --name ctop  -it --rm -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop";
      "dps" = "docker ps ";
      "dcrneup" = "docker compose up -f ~/docker-compose.yml -d ";
      "dcup" = "docker compose up -d ";
      "dcreup" = "docker compose up -d --build --force-recreate ";
      "drm" = "docker rm `docker ps -aq`";
      "dcp" = "docker compose -f ~/docker-compose.yml ";
      "dcporph" = "docker compose -f ~/docker-compose.yml --remove-orphans ";
    };

  };
in
{
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
    zsh = {
      enable = true;
      package = pkgs.zsh;
      # This actually doesn't do anything since Nix gives
      # oh-my-zsh responsibility for calling compinit
      enableCompletion = true;
      defaultKeymap = "viins";
      autosuggestion = {
        enable = false;
      };
      syntaxHighlighting.enable = true;
      sessionVariables = sharedShell.env // { };
      shellAliases = sharedShell.aliases // {
        "hig" = "history 0 | grep";
        "hmswitch" = ''
          hmswitchnoload;
          source ~/.zshrc
        '';
      };
      shellGlobalAliases = {
        G = "| grep";
      };
      dirHashes = {
        # cd ~code
        # "code" = "$HOME/code";
      };
      initExtraFirst = ''
        VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
        VI_MODE_SET_CURSOR=true
        ZSH_AUTOSUGGEST_STRATEGY=(history)
        # https://github.com/NixOS/nix/issues/1577
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        else
          echo "WARNING: nix-daemon.sh not found"
        fi

        # Load Pure theme
        fpath+=(${pkgs.pure-prompt}/share/zsh/site-functions)
        autoload -U promptinit; promptinit
        prompt pure
      '';
      initExtra = (builtins.readFile ../config/shell/.sharedrc) + "\n" + (builtins.readFile ../config/shell/zsh/.zshrc);
      profileExtra = builtins.readFile ../config/shell/zsh/.zprofile;
      history = {
        size = 10000;
        # append = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        extended = true;
        path = "${config.xdg.dataHome}/zsh/history";
      };
      plugins = [
        # FZF-tab needs to come before autosuggestions / syntax highlighting
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "v1.1.2";
            sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
          };
        }
        {
          name = "zsh-autosuggestions";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-autosuggestions";
            rev = "v0.7.0";
            sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
          };
        }
      ];
      oh-my-zsh = {
        enable = true;
        # Others: direnv
        plugins = [ "vi-mode" "thefuck" "aws" "docker" "helm" "kubectl" "yarn" "poetry" "tailscale" "terraform" "tmux" ];
        # theme = "robbyrussell";
        extraConfig = ''
          zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
        '';
      };
    };
    bash = {
      enable = true;
      enableCompletion = true;
      sessionVariables = sharedShell.env // { };
      shellAliases = sharedShell.aliases // {
        "hig" = "bat ~/.bash_history | grep";
        "hmswitch" = ''
          hmswitchnoload;
          source ~/.bashrc
        '';
      };
      initExtra = (builtins.readFile ../config/shell/.sharedrc) + "\n" + (builtins.readFile ../config/shell/bash/bashrc);
      profileExtra = builtins.readFile ../config/shell/bash/profile;
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
