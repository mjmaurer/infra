{
  lib,
  config,
  isDarwin,
  pkgs,
  pkgs-latest,
  nix-colors,
  ...
}:
let
  username = "ai" ;
in
{

  imports = [
    nix-colors.homeManagerModule
    # ../data

    ../modules/nix.nix

    ../modules/shell/shell.nix
    # ../modules/git/git.nix
    ../modules/ai/ai.nix
  ];

  modules = {
    ai.enable = lib.mkDefault true;
    aider.enable = lib.mkDefault true;
    claude.enable = lib.mkDefault true;
    codex-cli.enable = lib.mkDefault true;
    # git.enable = lib.mkDefault true;
  };

  home.homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";

  programs.home-manager.enable = true;

  colorScheme = nix-colors.colorSchemes.gruvbox-material-light-hard;
  xdg.enable = true;

  home = {
    # This might be set by the home-manager module for Darwin / NixOS
    username = lib.mkDefault username;
    packages = with pkgs-latest; [
      # Fonts
      pkgs.meslo-lgs-nf

      # Nix
      nil
      nix-prefetch-git
      nix-search-cli
      nixfmt-rfc-style
      cachix
      # nixpkgs-fmt
      # vulnix (was causing buidl issues)

      # Git
      pkgs.git-lfs
      gh

      # Other
      ripgrep
      rclone
      devenv
      awscli2
      postgresql
      glow
      yt-dlp
      gdown
      bat
      fd
      tree
      wget
      neofetch
      unzip
      p7zip
      tldr
    ];
  };

  programs = {
    htop.enable = true;
    jq.enable = true;
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
