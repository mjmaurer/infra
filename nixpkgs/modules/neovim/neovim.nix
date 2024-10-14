{ lib, config, pkgs, ... }:
let
  cfg = config.modules.neovim;
in
{
  options.modules.neovim = {
    enable = lib.mkEnableOption "neovim";
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      extraConfig = builtins.readFile ./config.vim;
      plugins = with pkgs.vimPlugins; [ vim-polyglot gruvbox-material ];
    };
  };
}
