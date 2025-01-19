{ pkgs, ... }: {
  i18n.defaultLocale = "en_US.UTF-8";
  console = with pkgs; {
    font = "${meslo-lgs-nf}/share/consolefonts/ter-132n.psf.gz";
    packages = [ meslo-lgs-nf ];
  };
  fonts.fonts = with pkgs; [ source-code-pro font-awesome ];
}
