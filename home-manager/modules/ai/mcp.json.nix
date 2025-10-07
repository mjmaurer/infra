{
  /* ---------------- NOTE ------------------------ */
  # You should also add a list of these to
  # claude/settings/local-settings-tmpl.jsonc
  # to make it easier to set up.

  mcpServers = {
    nixos = {
      command = "nix";
      args = [
        "run"
        "github:utensils/mcp-nixos"
        "--"
      ];
    } ;
  };
}
