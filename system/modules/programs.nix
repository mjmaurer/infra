# Programs I need to survive (and also partition)
{ lib, isDarwin, pkgs, ... }:
let
  isNixOS = !isDarwin;
in
lib.mkMerge [
  {
    environment.systemPackages = with pkgs; [
      which
      wget
      tmux
      tree
      w3m
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
  (lib.optionalAttrs isNixOS {
    environment.systemPackages = with pkgs; [
      parted
    ];
    programs = {
      zsh = {
        enable = true;
      };
      git = {
        enable = true;
        lfs.enable = true;
      };
    };
  })
  (lib.optionalAttrs isDarwin { })
]
