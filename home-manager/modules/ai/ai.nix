{
  lib,
  config,
  pkgs,
  mylib,
  pkgs-latest,
  tsScripts,
  ...
}:
let
  cfg = config.modules.ai;
  pythonPkg = mylib.py pkgs-latest;
  gitingestEnv = pythonPkg.withPackages (
    ps: with ps; [
      gitingest
    ]
  );
in
{
  imports = [
    ./harness/claude/claude.nix
    # ./harness/aider/aider.nix
    ./harness/codex-cli/codex-cli.nix
    # ./harness/opencode/opencode.nix
    ./harness/pi/pi.nix
  ];

  options.modules.ai = {
    enable = lib.mkEnableOption "AI agents and tools";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs-latest.mcp-nixos
      (pkgs.writeShellScriptBin "ai-setup" ''
        ${builtins.readFile ./ai-setup.sh}
      '')
      (pkgs.callPackage ./mcp-cli.nix { })
      (pkgs.writeShellScriptBin "gitingest" ''
        exec "${gitingestEnv}/bin/gitingest" "$@"
      '')
      (tsScripts.mkTsScript {
        name = "ai-context";
        script = ./scripts/ai-context.ts;
      })
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
