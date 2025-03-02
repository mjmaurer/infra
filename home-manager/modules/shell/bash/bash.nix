{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.bash;
  commonShell = config.modules.commonShell;
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
      initExtra = commonShell.assembleInitExtra ./.bashrc;
      # profileExtra = builtins.readFile ./.profile;
    };
  };
}
