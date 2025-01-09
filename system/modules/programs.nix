# Programs I need to survive (and also partition)
{ pkgs, ... }:
{
  programs = {
    zsh = {
      enable = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
    };
  };
  environment.systemPackages = with pkgs; [
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
