{ config, pkgs, lib, ... }:

{
  nixpkgs = {
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (pkgs.lib.getName pkg) [
          "duplicacy"
        ];
      };
  };

  programs.home-manager.enable = true;

  home.username = "mjmaurer";
  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    duplicacy
    nil
    nixpkgs-fmt
    ripgrep
    rclone
    vulnix
    youtube-dl
    gdown
    nixfmt
    bat
    htop
    wget
    neofetch
    unzip
    speedtest-cli
    git-lfs
    gh
    p7zip
  ];

  home.file = {
    ".continue/config.json" = {
      source = ../config/continuedev/config.json;
    };
    ".continue/config.ts" = {
      source = ../config/continuedev/config.ts;
    };
  };

  services.gpg-agent = {
    enable = lib.mkDefault true;
    defaultCacheTtl = 1800;
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BOBBY_PORT = 7850;
      AUTOMATIC_PORT = 7860;
      RVC_PORT = 7865;
      PLEX_WEB_PORT = 32400;
      JELLYFIN_WEB_PORT = 8096;
    };
    initExtra = builtins.readFile ../config/bash/bashrc;
    profileExtra = builtins.readFile ../config/bash/profile;
    shellAliases = {
      ".." = "cd ..";
      "gc" = "git commit -v";
      "gcs" = "git commit -v --gpg-sign";
      "ga" = "git add --all";
      "gs" = "git status";
      "rg" = "rg --hidden";
      "hig" = "bat ~/.bash_history | grep";
      "la" = lib.mkDefault "ls -A --color";
      "ls" = lib.mkDefault "ls --color";
      "hmswitch" = ''
        home-manager -f ~/.config/nixpkgs/machines/$MACHINE_NAME.nix switch -b backup;
        source ~/.bashrc;
      '';
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

  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.git = {
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

  programs.neovim = {
    enable = true;
    vimAlias = true;
    extraConfig = builtins.readFile ../config/vim/config.vim;
    plugins = with pkgs.vimPlugins; [ vim-polyglot ];
  };
}
