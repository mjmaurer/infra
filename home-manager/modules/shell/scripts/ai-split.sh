export PATH="$PATH:/opt/homebrew/bin:~/.nix-profile/bin"

export WINDOW_TITLE="AI"
export WINDOW_ID=$(aerospace list-windows --all --json | jq -r '.[] | select(."app-name" == "alacritty" and ."window-title" == $WINDOW_TITLE) | ."window-id"' | xargs)
echo "Window Title: $WINDOW_TITLE"
echo "Window ID: $WINDOW_ID"

if [[ -z "${WINDOW_ID// /}" ]]; then
  # WINDOW_ID is empty or all whitespace
  echo "closing $WINDOW_ID"
  aerospace close --window-id $WINDOW_ID
fi

# Kill existing tmux session named 'ai' if it exists
tmux kill-session -t ai 2>/dev/null || true

alacritty --title $WINDOW_TITLE --command ~/.nix-profile/bin/zsh -lc 'AI_CMD="$1" tmuxp load ai'