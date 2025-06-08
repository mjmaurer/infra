{
  lib,
  pkgs,
  nix-colors,
  username,
  ...
}:
{

  # Never change this.
  # If you need a newer version, supply via machine's flake.nix config.
  home.stateVersion = lib.mkDefault "22.05";

  # imports = lib.pipe ../modules [
  #   builtins.readDir
  #   (lib.filterAttrs (name: _: lib.hasSuffix ".nix" name))
  #   (lib.mapAttrsToList (name: _: ./services + "/${name}"))
  # ];
  imports = [
    nix-colors.homeManagerModule
    ../data

    ../modules/nix.nix

    ../modules/shell/shell.nix
    ../modules/crypt/crypt.nix
    ../modules/git/git.nix
    ../modules/tmux/tmux.nix
    ../modules/aider/aider.nix
    ../modules/claude/claude.nix
    ../modules/intellibar/intellibar.nix
    ../modules/aichat/aichat.nix
    ../modules/llm/llm.nix
    ../modules/neovim/neovim.nix
  ];

  # When adding here, consider if these should be disabled for some OS.
  modules = {
    tmux.enable = lib.mkDefault true;
    aider.enable = lib.mkDefault true;
    claude.enable = lib.mkDefault true;
    aichat.enable = lib.mkDefault true;
    llm.enable = lib.mkDefault true;
    neovim.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
  };

  # This exposes `config.colorScheme.palette.*` based on the color scheme.
  # You could define a custom scheme, or even defined based on a wallpaper pic.
  colorScheme = nix-colors.colorSchemes.gruvbox-material-light-hard;

  # Reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;
  # Sets up XDG_DATA_HOME, XDG_CONFIG_HOME, XDG_CACHE_HOME, etc.
  xdg.enable = true;

  home = {
    # This might be set by the home-manager module for Darwin / NixOS
    username = lib.mkDefault username;
    file = {
      # Used for various REPLs (python, psql, etc.)
      ".inputrc".text = ''
        # Show completion options immediately without requiring a second tab
        set show-all-if-ambiguous on
        set completion-ignore-case on
        # Add trailing slash to completed [symlinked] directory names
        set mark-directories on
        set mark-symlinked-directories on
        set match-hidden-files on
        # Show file type indicators (*/=>@|) for completions
        set visible-stats on
        set keymap vi
        set editing-mode vi-insert
      '';
    };
    packages = with pkgs; [
      # Fonts
      meslo-lgs-nf

      # Nix
      nil
      nix-prefetch-git
      nix-search-cli
      nixfmt-rfc-style
      cachix
      # nixpkgs-fmt
      # vulnix (was causing buidl issues)

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
      fd
      tree
      devenv
      wget
      neofetch
      unzip
      speedtest-cli
      p7zip
      thefuck
      awscli2
      tldr
    ];
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      config = builtins.fromTOML ''
        [global]
        warn_timeout = "-1s"
        hide_env_diff = true
      '';
    };
    htop.enable = true;
    jq.enable = true;
    # zathura.enable = true;
    lsd = {
      enable = true;
      enableZshIntegration = false;
      enableBashIntegration = false;
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
  };
}
