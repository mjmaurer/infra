{ pkgs, ... }:
{
  programs = {
    zsh = {
      enable = true;
    };
  };
  environment.systemPackages = with pkgs; [
    # Basic Command line interfaces
    which
    wget
    tmux
    tree
    w3m
    parted
    ripgrep
    unzip
    xxd
    tcpdump
    neovim
    gnumake
    parallel
    findutils
    xorriso
    bind
  ];
}
