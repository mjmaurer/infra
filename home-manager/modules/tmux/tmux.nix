{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modules.tmux;
  tmuxpDir = ./tmuxp;
  tmuxpDirContents = builtins.readDir tmuxpDir;
  aiFiles =
    builtins.filter (n:
      tmuxpDirContents.${n} == "regular"
      && lib.hasPrefix "ai" n
      && (lib.hasSuffix ".yaml" n || lib.hasSuffix ".yml" n))
    (builtins.attrNames tmuxpDirContents);
  stripExt = n:
    if lib.hasSuffix ".yaml" n then
      lib.removeSuffix ".yaml" n
    else
      lib.removeSuffix ".yml" n;
  aiSessions = builtins.map stripExt aiFiles;
  aiSessionsStr = lib.concatStringsSep " " aiSessions;
in
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
{
  options.modules.tmux = {
    enable = lib.mkEnableOption "tmux";
  };

  config = lib.mkIf cfg.enable {
    # Expose available ai* tmuxp sessions to shells/scripts
    home.sessionVariables = {
      TMUXP_AI_SESSIONS = aiSessionsStr;
      TMUXP_AI_STUTTER = "0.3";
    };

    xdg.configFile = {
      "tmuxp" = {
        source = ./tmuxp;
        recursive = true;
      };
    };
    home.file = {
      ".local/bin/ai-split.sh" = {
        source = ./scripts/ai-split.sh;
        executable = true;
      };
      ".local/bin/ai-prompt-compose.sh" = {
        source = ./scripts/ai-prompt-compose.sh;
        executable = true;
      };
    };
    programs.tmux = {
      enable = true;
      tmuxp.enable = true;
      shell = "${pkgs.zsh}/bin/zsh";
      terminal = "xterm-256color";
      historyLimit = 100000;
      plugins = with pkgs; [
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
