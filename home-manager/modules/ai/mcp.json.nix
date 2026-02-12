{
  # ---------------- NOTE ------------------------
  # This is just sourced for mcp-cli.
  # We avoid spinning these up by default via vscode, but that would be another option if we wanted to.

  mcpServers = {
    nixos = {
      command = "mcp-nixos";
    };
  };
}
