{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.modules.ente-auth;
in
{
  options.modules.ente-auth = {
    enable = lib.mkEnableOption "ente-auth";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.ente-auth ];
  };
}
