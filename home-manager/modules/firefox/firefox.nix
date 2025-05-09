{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modules.firefox;
in
{
  options.modules.firefox = {
    enable = lib.mkEnableOption "firefox";
  };

  # Good place to start for more options:
  # https://github.com/Misterio77/nix-config/blob/main/home/gabriel/features/desktop/common/firefox.nix
  config = lib.mkIf cfg.enable {
    xdg.configFile."environment.d/firefox-wayland.conf" = lib.mkIf config.modules.wayland.enable {
      text = ''
        MOZ_ENABLE_WAYLAND=1
        MOZ_USE_XINPUT2=1
      '';
    };
    programs = {
      firefox = {
        enable = true;
      };
    };
  };
}
