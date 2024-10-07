{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.bash;
  commonShell = import ../../common/shell.nix { inherit lib; };
in
{
  options.modules.bash = {
    enable = lib.mkEnableOption "bash";
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      sessionVariables = commonShell.sessionVariables // { };
      shellAliases = commonShell.shellAliases // {
        "hig" = "bat ~/.bash_history | grep";
        "hmswitch" = ''
          hmswitchnoload;
          source ~/.bashrc
        '';
      };
      initExtra = commonShell.rc + "\n" + (builtins.readFile ./.bashrc);
      profileExtra = builtins.readFile ./.profile;
    };
  };
}
