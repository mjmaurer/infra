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
