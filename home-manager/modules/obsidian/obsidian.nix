{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.obsidian;
in
{
  options.modules.obsidian = {
    enable = lib.mkEnableOption "obsidian";

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "Documents/obsidian/Personal";
      description = "Path to the Obsidian vault.";
    };

    justConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "[NOOP currently] If true, only copy the config files without installing the package. For packages installed external to Nix.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = if cfg.justConfig then [ ] else [ pkgs.obsidian ];

    home.file = {
      "${cfg.vaultPath}/.obsidian.vimrc" = {
        source = ./.obsidian.vimrc;
      };
    };
  };
}
