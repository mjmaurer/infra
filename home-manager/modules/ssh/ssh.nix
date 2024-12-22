{ lib, config, pkgs, ... }:
let
  cfg = config.modules.ssh;
in
{
  options.modules.ssh = {
    enable = lib.mkEnableOption "ssh";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      includes = [
        # For manual/local configurations
        "~/.ssh/config.local"
      ];
      addKeysToAgent = "yes";
    };

    services.ssh-agent = {
      enable = lib.mkDefault true;
    };
  };
}
