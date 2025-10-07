# ALLOW specifies which commands are allowed without approval
# DENY will completely block the command's use

# "Bash(rm -rf:*)" - Matches all commands that start with "rm -rf"
{
  includeCoAuthoredBy = false;
  permissions = {
    allow = [
      "WebFetch(domain:github.com)"
      "WebFetch(domain:raw.githubusercontent.com)"

      "Bash(nix flake check:*)"
      "Bash(nix-instantiate --parse:*)"
      "Bash(nixfmt:*)"

      "Bash(git status:*)"
      "Bash(git diff:*)"

      "Edit(README.md)"
      "Edit(AGENTS.md)"
    ];
    deny = [

    ];
  };
  # Don't use servers in project's mcp.json by default
  enableAllProjectMcpServers = false;
  env = {
    DISABLE_AUTOUPDATER = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_TELEMETRY = 1;
  };
  hooks = {
    Notification = [
      {
        hooks = [
          {
            type = "command";
            command = "afplay ${../../../sounds/short_whistle.mp3}";
          }
        ];
      }
    ];
    Stop = [
      {
        hooks = [
          {
            type = "command";
            command = "afplay ${../../../sounds/short_whistle.mp3}";
          }
        ];
      }
    ];
  };
}
