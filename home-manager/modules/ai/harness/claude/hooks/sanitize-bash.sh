#!/usr/bin/env bash
# PreToolUse hook for Bash tool calls.
# Blocks dangerous flags in 'find' and 'ripgrep' commands.
# Exit 2 = block the tool use.

set -euo pipefail

cmd=$(jq -r '.tool_input.command // empty')

if [ -z "$cmd" ]; then
  exit 0
fi

# Block find with dangerous flags
if printf '%s' "$cmd" | grep -qw 'find' \
  && printf '%s' "$cmd" | grep -qE '\-(exec|execdir|ok|okdir|delete|fprint|fprint0|fprintf)'; then
  echo "Blocked: find with -exec/-execdir/-ok/-okdir/-delete/-fprint/-fprint0/-fprintf is disallowed" >&2
  exit 2
fi

# Block ripgrep with --pre (arbitrary command execution via preprocessor)
if printf '%s' "$cmd" | grep -qw 'rg' \
  && printf '%s' "$cmd" | grep -q -- '--pre'; then
  echo "Blocked: ripgrep with --pre is disallowed" >&2
  exit 2
fi

# Block sed with side effects (in-place editing, file writes, command execution)
if printf '%s' "$cmd" | grep -qEw 'sed'; then
  # In-place editing: -i, -ni, -Ei, -ibak, -ie, -i.bak, -i '', --in-place
  if printf '%s' "$cmd" | grep -qE '(^|\s)-[a-zA-Z]*i|--in-place'; then
    echo "Blocked: sed with -i/--in-place is disallowed" >&2
    exit 2
  fi
  # Script file: -f/--file loads commands from an external file (can contain w/e/W)
  if printf '%s' "$cmd" | grep -qE '(^|\s)-[a-zA-Z]*f\b|--file'; then
    echo "Blocked: sed with -f/--file is disallowed" >&2
    exit 2
  fi
  # Write to file: w/W as substitution flag (s/…/…/gw) or standalone command (5w, /pat/w)
  if printf '%s' "$cmd" | grep -qE '[^a-zA-Z][gIilMpe]*[wW]\s+\S|[^a-zA-Z][gIilMpe]*[wW]$'; then
    echo "Blocked: sed with w/W (write to file) is disallowed" >&2
    exit 2
  fi
  # Execute: e flag/command — runs pattern space as shell command (excludes -e flag)
  if printf '%s' "$cmd" | grep -qE '[^a-zA-Z-][gIilMpwW]*e(\s|$|[^a-zA-Z])'; then
    echo "Blocked: sed with e (execute) is disallowed" >&2
    exit 2
  fi
fi

# Block awk with side effects (system calls, file writes, pipes, in-place editing)
if printf '%s' "$cmd" | grep -qEw 'awk|gawk|mawk|nawk'; then
  # In-place editing: -i, -ni, --in-place (gawk extension)
  if printf '%s' "$cmd" | grep -qE '(^|\s)-[a-zA-Z]*i|--in-place'; then
    echo "Blocked: awk with -i/--in-place is disallowed" >&2
    exit 2
  fi
  # Script file: -f loads program from an external file (can contain system/pipes/redirections)
  if printf '%s' "$cmd" | grep -qE '(^|\s)-f\b'; then
    echo "Blocked: awk with -f is disallowed" >&2
    exit 2
  fi
  # Shell command execution via system()
  if printf '%s' "$cmd" | grep -qE 'system\s*\('; then
    echo "Blocked: awk with system() is disallowed" >&2
    exit 2
  fi
  # Pipe to/from commands: "cmd" | getline, "cmd" |& getline, print/printf … | "cmd", print/printf … |& "cmd"
  # Note: pipe to unquoted variable (print | var) remains hard to catch without false positives on strings containing |
  if printf '%s' "$cmd" | grep -qE '\|&?\s*getline|print[f]?\b.*\|&?\s*\(?\s*"'; then
    echo "Blocked: awk with pipe to/from commands is disallowed" >&2
    exit 2
  fi
  # Output redirection to files (> or >>)
  if printf '%s' "$cmd" | grep -qE '>\s*"[^"]*"|>\s*[a-zA-Z_/($]|>>\s*"[^"]*"|>>\s*[a-zA-Z_/($]'; then
    echo "Blocked: awk with output redirection to files is disallowed" >&2
    exit 2
  fi
  # Dynamic extension loading (gawk)
  if printf '%s' "$cmd" | grep -qE '@load'; then
    echo "Blocked: awk with @load is disallowed" >&2
    exit 2
  fi
fi
