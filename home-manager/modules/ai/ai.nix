{
  lib,
  config,
  pkgs,
  pkgs-latest,
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
      pkgs-latest.mcp-nixos
      (pkgs.writeShellScriptBin "ai-setup" ''
        ${builtins.readFile ./setup.sh}
      '')
      (pkgs.callPackage ./mcp-cli.nix { })
    ];

    # Store centralized AGENTS.md in config directory
    home.file = {
      ".config/ai/repo-config-nix/AGENTS.md" = {
        source = ./AGENTS_TMPL.md;
      };
      # ".config/ai/mcp.json" = {
      #   source = (pkgs.formats.json { }).generate "mcp.json" (import ./mcp.json.nix);
      # };
    };
  };
}
