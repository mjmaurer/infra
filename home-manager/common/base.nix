{ inputs, config, pkgs, lib, username, ... }:
{
  # imports = lib.pipe ../modules [
  #   builtins.readDir
  #   (lib.filterAttrs (name: _: lib.hasSuffix ".nix" name))
  #   (lib.mapAttrsToList (name: _: ./services + "/${name}"))
  # ];

  # Never change this.
  # If you need a newer version, you have to supply it to new users somehow. 
  # The easiest option is to register a mkDefaultHomeConfig (with stateVersion) in flake.nix
  # for each new user. 
  # Another option is to start creating
  # a home-manager flake (via `nix run home-manager/master -- init`)
  # and then manage the stateVersion separately for each user that requires a newer version.
  # You could use `--recreate-lock-file or --update-input` to automatically
  # update the the central flake on every switch.
  home.stateVersion = lib.mkDefault "22.05";

  imports = [
    inputs.nix-colors.homeManagerModule

    ./shell/common-shell.nix

    ../modules/alacritty/alacritty.nix
    ../modules/continuedev/continuedev.nix
    ../modules/karabiner/karabiner.nix
    ../modules/obsidian/obsidian.nix
    ../modules/zsh/zsh.nix
    ../modules/ssh/ssh.nix
    ../modules/git/git.nix
    ../modules/gpg/gpg.nix
    ../modules/bash/bash.nix
    ../modules/duplicacy/duplicacy.nix
    ../modules/tmux/tmux.nix
    ../modules/aerospace/aerospace.nix
    ../modules/aider/aider.nix
    ../modules/neovim/neovim.nix
    ../modules/aichat/aichat.nix
    ../modules/wayland/wayland.nix
    ../modules/firefox/firefox.nix
  ];

  # This exposes `config.colorScheme.palette.*` based on the color scheme.
  # You could define a custom scheme, or even defined based on a wallpaper pic.
  colorScheme = inputs.nix-colors.colorSchemes.gruvbox-material-light-hard;

  # Reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  modules = {
    gpg.enable = true;
    zsh.enable = true;
    bash.enable = true;
    tmux.enable = true;
    aider.enable = true;
    aichat.enable = true;
    neovim.enable = true;
    alacritty.enable = true;
    git.enable = true;
    ssh.enable = true;
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
      username = lib.mkDefault username;
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
      enableBashIntegration = true;
      enableZshIntegration = true;
      config = builtins.fromTOML ''
        [global]
        warn_timeout = "-1s"
      '';
    };
    htop.enable = true;
    jq.enable = true;
    # zathura.enable = true;
    lsd = {
      enable = true;
      enableAliases = false;
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
