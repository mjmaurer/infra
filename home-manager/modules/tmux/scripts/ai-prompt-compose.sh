#!/usr/bin/env bash
set -euo pipefail
export PATH="$PATH:/opt/homebrew/bin:$HOME/.nix-profile/bin"

# This script accepts no CLI arguments; mode is chosen via tmux picker
if [ "$#" -gt 0 ]; then
  echo "Error: ai-prompt-compose takes no arguments. Use the tmux picker to choose a mode." >&2
  exit 2
fi

# Decouple from tmux: one dedicated Alacritty window handles both selection and prompt
workdir="${HOME}/.local/state/llm"
mkdir -p "$workdir"
tmpdir="$(mktemp -d "${workdir}/compose.XXXXXX")"
sel_file="${tmpdir}/mode"
prompt_file="${tmpdir}/prompt.md"
select_script="${tmpdir}/select.sh"
compose_script="${tmpdir}/compose.sh"

# Build the selection UI script
cat > "$select_script" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

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
    '' ) ;;
    * )
      if [[ "$ans" =~ ^[0-9]+$ ]]; then
        idx=$((ans-1))
        if [ $idx -ge 0 ] && [ $idx -lt ${#modes[@]} ]; then
          mode="${modes[$idx]}"
        fi
      else
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

# Build the combined compose flow to run inside Alacritty
cat > "$compose_script" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$PATH:/opt/homebrew/bin:$HOME/.nix-profile/bin"
unset TMUX || true

SELECT="$1"
SEL_FILE="$2"
PROMPT_FILE="$3"

# Cleanup tmpdir on exit
TMPDIR="$(dirname "$PROMPT_FILE")"
cleanup() { rm -rf "$TMPDIR" 2>/dev/null || true; }
trap cleanup EXIT

# 1) Mode picker
"$SELECT" "$SEL_FILE" || exit 130
if [ ! -s "$SEL_FILE" ]; then
  exit 130
fi
mode="$(cat "$SEL_FILE")"

# 2) Prompt compose in Neovim
: > "$PROMPT_FILE"
nvim '+set ft=markdown' '+setlocal spell' '+startinsert' "$PROMPT_FILE"

prompt="$(sed -e 's/[[:space:]]*$//' "$PROMPT_FILE")"
if [ -z "${prompt// /}" ]; then
  exit 0
fi

# 3) Launch AI tmuxp session, fully detached from this window
if command -v setsid >/dev/null 2>&1; then
  setsid -f "$HOME/.local/bin/ai-split.sh" ". " "$mode $prompt" >/dev/null 2>&1
else
  nohup "$HOME/.local/bin/ai-split.sh" ". " "$mode $prompt" >/dev/null 2>&1 &
  disown || true
fi

# Determine the final window title for this mode (matches ai-split.sh logic)
if [[ "$mode" == ai || "$mode" == ai-* ]]; then
  target_title="$mode"
else
  target_title="ai-$mode"
fi

# Wait briefly for the new window to appear, then optionally focus it
if command -v aerospace >/dev/null 2>&1; then
  for _ in {1..30}; do
    id="$(aerospace list-windows --all --json \
      | jq -r --arg t "$target_title" \
        '.[] | select(."app-name"=="alacritty" and ."window-title"==$t) | ."window-id"' \
      | xargs)"
    if [[ -n "${id// /}" ]]; then
      aerospace focus --window-id "$id" 2>/dev/null || true
      break
    fi
    sleep 0.1
  done
else
  # Fallback: small delay to avoid teardown race if aerospace isn't available
  sleep 0.5
fi

exit 0
EOS
chmod +x "$compose_script"

# Helper to close existing window by title (if aerospace is available)
close_by_title() {
  if command -v aerospace >/dev/null 2>&1; then
    local id
    id=$(
      aerospace list-windows --all --json \
        | jq -r --arg title "$1" \
          '.[] | select(."app-name" == "alacritty" and ."window-title" == $title) | ."window-id"' \
        | xargs
    )
    if [[ -n "${id// /}" ]]; then
      aerospace close --window-id "$id"
    fi
  fi
}

COMPOSE_TITLE="AI Compose"
close_by_title "$COMPOSE_TITLE"

# Launch in background so this terminal isn't blocked
alacritty \
  --working-directory "$workdir" \
  -o font.size=13 \
  --title "$COMPOSE_TITLE" \
  --command ~/.nix-profile/bin/zsh -lc "'$compose_script' '$select_script' '$sel_file' '$prompt_file'" \
  >/dev/null 2>&1 </dev/null &

exit 0
