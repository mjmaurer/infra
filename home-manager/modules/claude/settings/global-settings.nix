# ALLOW specifies which commands are allowed without approval
# DENY will completely block the command's use

# "Bash(rm -rf:*)" - Matches all commands that start with "rm -rf"
{
  includeCoAuthoredBy = false;
  preferredNotifChannel = "terminal_bell";
  permissions = {
    allow = [
      "WebFetch(domain:github.com)"
      "WebFetch(domain:raw.githubusercontent.com)"
      "Bash(nix flake check:*)"
      "Bash(nixfmt:*)"
      "Edit(AI_README.md)"
      "Edit(README.md)"
    ];
    deny = [

    ];
  };

  env = {
    DISABLE_AUTOUPDATER = 1;
    DISABLE_ERROR_REPORTING = 1;
    DISABLE_TELEMETRY = 1;
  };
}
