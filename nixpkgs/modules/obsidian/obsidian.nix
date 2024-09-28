{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.configuration.obsidian;
in
{
  options.configuration.obsidian = {
    enable = lib.mkEnableOption "obsidian";

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "Documents/obsidian/Personal";
      description = "Path to the Obsidian vault.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      "${cfg.vaultPath}/.obsidian.vimrc" = {
        source = ./.obsidian.vimrc;
      };
    };
  };
}
