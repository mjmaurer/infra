{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  home = config.users.users.${username}.home;
  mkAllowRW = path: ''
    (allow file-read* file-write* (subpath "${path}"))
  '';
  mkAllowRO = path: ''
    (allow file-read* (subpath "${path}"))
  '';

  profileFile = pkgs.writeText "ai-sandbox.sb" ''
    ${builtins.readFile ./ai-sandbox.sb}
  '';

  wrapper = pkgs.writeShellScriptBin "ai-sandbox" ''
    set -euo pipefail

    # 2. Get Current Working Directory
    # We use pwd -P to resolve symlinks, ensuring the sandbox path matches the filesystem.
    CURRENT_DIR="$(pwd -P)"

    if [ "$#" -lt 1 ]; then
      echo "usage: ai-sandbox <command> [args...]" >&2
      echo "Runs <command> inside a restrictive sandbox-exec profile." >&2
      echo "Current working directory: ''${CURRENT_DIR}" >&2
      exit 2
    fi

    # Pass command and args through exactly.
    exec /usr/bin/sandbox-exec -D CWD="$CURRENT_DIR" -f "${profileFile}" -- "$@"
  '';

in
{

  environment.systemPackages = [
    wrapper

    (pkgs.writeShellScriptBin "ai-sandbox-log" ''
      set -euo pipefail

      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
      echo "NOTE: This log viewer filters for 'claude' and 'bash' messages only."
      echo "These names may not be stable over time."
      echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

      exec /usr/bin/log stream --style syslog --predicate 'sender == "sandboxd" OR eventMessage CONTAINS "deny"' | grep -E 'claude|bash'
    '')
  ];

  # Keep the profile around in the system closure for inspection.
  environment.etc."claude-sandbox/claude.sb".source = profileFile;
}
