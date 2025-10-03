{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modules.ai;
in
{
  imports = [
    ./agents/claude/claude.nix
    ./agents/aider/aider.nix
    ./agents/codex-cli/codex-cli.nix
  ];

  options.modules.ai = {
    enable = lib.mkEnableOption "AI agents and tools";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "ai-setup" ''
        ${builtins.readFile ./setup.sh}
      '')
    ];

    # Store centralized AGENTS.md in config directory
    home.file = {
      ".config/ai/AGENTS.md" = {
        source = ./AGENTS.md;
      };
    };
  };
}
