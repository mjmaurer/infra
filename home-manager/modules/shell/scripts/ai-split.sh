export PATH="$PATH:/opt/homebrew/bin:~/.nix-profile/bin"

export WINDOW_TITLE="AI"
export WINDOW_ID=$(
  aerospace list-windows --all --json \
    | jq -r --arg title "$WINDOW_TITLE" \
      '.[] | select(."app-name" == "alacritty" and ."window-title" == $title) | ."window-id"' \
    | xargs
)

echo "Query: '$@'"
echo "Window ID: $WINDOW_ID"

if [[ -z "${WINDOW_ID// /}" ]]; then
  # WINDOW_ID is empty or all whitespace
  echo "closing $WINDOW_ID"
  aerospace close --window-id $WINDOW_ID
fi

# Kill existing tmux session named 'ai' if it exists
tmux kill-session -t ai 2>/dev/null || true

export AI_CMD="$@"
alacritty \
  --working-directory ~/.local/state/llm \
  -o font.size=13 \
  --title "$WINDOW_TITLE" \
  --command ~/.nix-profile/bin/zsh -lc "tmuxp load ai"