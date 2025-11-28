{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ];

  config = {

    # Never change this here. Only in flake.nix
    system.stateVersion = lib.mkDefault "24.11";

    time.hardwareClockInLocalTime = true;

    i18n.defaultLocale = "en_US.UTF-8";
    console = {
      font = "ter-124b";
      packages = with pkgs; [
        terminus_font
      ];
      keyMap = "us";
      # font = "${pkgs.nerd-fonts.meslo-lg}/share/consolefonts/ter-132n.psf.gz";
      # packages = [ pkgs.nerd-fonts.meslo-lg ];
    };

    environment = {
      systemPackages = with pkgs; [
        pciutils
        which
        wget
        tmux
        tree
        w3m
        ripgrep
        unzip
        lsof
        xxd
        tcpdump
        neovim
        gnumake
        parallel
        findutils
        xorriso
        bind
        parted
      ];
    };
    programs = {
      zsh = {
        enable = true;
      };
      git = {
        enable = true;
        lfs.enable = true;
      };
    };
  };
}
