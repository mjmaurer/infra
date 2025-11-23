#!/usr/bin/env bash
set -euo pipefail
export PATH="$PATH:/opt/homebrew/bin:$HOME/.nix-profile/bin"

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
mode=""
while [ -z "$mode" ]; do
  clear
  printf "Select AI profile:\n\n"
  printf "  1) fast      - single fast model\n"
  printf "  2) code      - code assistants\n"
  printf "  3) thinking  - o3/sonnet trio\n"
  printf "  q) cancel\n\n"
  printf "> "
  read -r ans
  case "${ans}" in
    1|fast|f) mode="fast" ;;
    2|code|c) mode="code" ;;
    3|thinking|t) mode="thinking" ;;
    q|Q) exit 130 ;;
    *) ;;
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

case "$mode" in
  fast)
    exec "$HOME/.local/bin/ai-split.sh" "$prompt"
    ;;
  code)
    exec "$HOME/.local/bin/ai-split.sh" c "$prompt"
    ;;
  thinking)
    exec "$HOME/.local/bin/ai-split.sh" t "$prompt"
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    exit 1
    ;;
esac
