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
    ./harness/claude/claude.nix
    # ./harness/aider/aider.nix
    ./harness/codex-cli/codex-cli.nix
    ./harness/opencode/opencode.nix
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
      ".config/ai/repo-config-nix/skills" = {
        source = ./skills;
      };
      ".config/ai/sounds" = {
        source = ./sounds;
      };
      ".config/mcp/mcp_servers.json" = {
        source = (pkgs.formats.json { }).generate "mcp_servers.json" (import ./mcp.json.nix);
      };
      # ".config/ai/mcp.json" = {
      #   source = (pkgs.formats.json { }).generate "mcp.json" (import ./mcp.json.nix);
      # };
    };
  };
}
