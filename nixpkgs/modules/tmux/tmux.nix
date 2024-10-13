{ lib, config, pkgs, ... }:
let
  cfg = config.modules.tmux;
  #   tmux-super-fingers = pkgs.tmuxPlugins.mkTmuxPlugin
  #     {
  #       pluginName = "tmux-super-fingers";
  #       version = "unstable-2023-01-06";
  #       src = pkgs.fetchFromGitHub {
  #         owner = "artemave";
  #         repo = "tmux_super_fingers";
  #         rev = "2c12044984124e74e21a5a87d00f844083e4bdf7";
  #         sha256 = "sha256-cPZCV8xk9QpU49/7H8iGhQYK6JwWjviL29eWabuqruc=";
  #       };
  #     };
in
{
  options.modules.tmux = {
    enable = lib.mkEnableOption "tmux";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "xterm-256color";
      historyLimit = 100000;
      plugins = with pkgs;
        [
          # Sensible installed by default
          # {
          #   plugin = tmuxPlugins.sensible; 
          #   extraConfig = ''
          #     run-shell ${pkgs.tmuxPlugins.sensible.rtp}
          #   '';
          # }
          # {
          #   plugin = tmux-super-fingers;
          #   extraConfig = "set -g @super-fingers-key f";
          # }
          # tmuxPlugins.better-mouse-mode
        ];
      # Nix home-manager tmuxConf includes a bunch of defaults we don't want:
      extraConfig = builtins.readFile ./tmux.conf;
    };
  };
}
