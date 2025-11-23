#!/usr/bin/env bash
set -euo pipefail
export PATH="$PATH:/opt/homebrew/bin:$HOME/.nix-profile/bin"

# This script accepts no CLI arguments; mode is chosen via tmux picker
if [ "$#" -gt 0 ]; then
  echo "Error: ai-prompt-compose takes no arguments. Use the tmux picker to choose a mode." >&2
  exit 2
fi

# Require a running tmux client to target the popup at
if ! tmux list-clients >/dev/null 2>&1; then
  echo "No tmux clients found; ensure tmux is running." >&2
  exit 1
fi
TARGET_CLIENT="$(tmux list-clients -F '#{client_name}' | head -n1)"
if [ -z "${TARGET_CLIENT:-}" ]; then
  echo "No attached tmux clients found." >&2
  exit 1
fi

workdir="${HOME}/.local/state/llm"
mkdir -p "$workdir"
tmpdir="$(mktemp -d "${workdir}/compose.XXXXXX")"
sel_file="${tmpdir}/mode"
prompt_file="${tmpdir}/prompt.md"
select_script="${tmpdir}/select.sh"

cat > "$select_script" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# Build list from TMUXP_AI_SESSIONS, fallback to a sane default
modes=()
if [ -n "${TMUXP_AI_SESSIONS:-}" ]; then
  for s in ${TMUXP_AI_SESSIONS}; do
    modes+=("$s")
  done
else
  modes=(ai-fast ai-code ai)
fi

mode=""
while [ -z "$mode" ]; do
  clear
  printf "Select AI tmuxp session:\n\n"
  i=1
  for s in "${modes[@]}"; do
    printf "  %d) %s\n" "$i" "$s"
    i=$((i+1))
  done
  printf "  q) cancel\n\n> "
  read -r ans
  case "${ans}" in
    q|Q) exit 130 ;;
    '' ) ;;  # re-prompt
    * )
      if [[ "$ans" =~ ^[0-9]+$ ]]; then
        idx=$((ans-1))
        if [ $idx -ge 0 ] && [ $idx -lt ${#modes[@]} ]; then
          mode="${modes[$idx]}"
        fi
      else
        # allow typing the name directly
        for s in "${modes[@]}"; do
          if [ "$ans" = "$s" ]; then
            mode="$s"
            break
          fi
        done
      fi
      ;;
  esac
done
printf "%s" "$mode" > "$1"
EOS
chmod +x "$select_script"

# Popup 1: choose the tmuxp profile
if ! tmux display-popup -t "$TARGET_CLIENT" -w 60% -h 40% -E "$select_script '$sel_file'"; then
  rm -rf "$tmpdir"
  exit 130
fi
[ -s "$sel_file" ] || { rm -rf "$tmpdir"; exit 130; }
mode="$(cat "$sel_file")"


# Popup 2: compose the prompt in Neovim
: > "$prompt_file"
if ! tmux display-popup -t "$TARGET_CLIENT" -w 80% -h 80% -E "nvim '+set ft=markdown' '+setlocal spell' '+startinsert' '$prompt_file'"; then
  rm -rf "$tmpdir"
  exit 130
fi

prompt="$(sed -e 's/[[:space:]]*$//' "$prompt_file")"
if [ -z "${prompt// /}" ]; then
  rm -rf "$tmpdir"
  exit 0
fi

exec "$HOME/.local/bin/ai-split.sh" ". " "$mode $prompt"
