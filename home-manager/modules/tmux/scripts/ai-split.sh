export PATH="$PATH:/opt/homebrew/bin:~/.nix-profile/bin"

if [[ "$@" == ". "* ]]; then
  echo "Custom session mode"
  # Remove the period and space
  args="${@:2}"
  export TMUXP_SESSION="ai-${args%% *}"
  export AI_CMD="${args#* }"
elif [[ "$@" == "t "* ]]; then
  echo "Thinking mode"
  export AI_CMD="${@:2}"
  export TMUXP_SESSION="ai"
elif [[ "$@" == "c "* ]]; then
  echo "Code mode"
  export AI_CMD="${@:2}"
  export TMUXP_SESSION="ai-code"
else
  echo "Fast mode"
  export AI_CMD="$@"
  export TMUXP_SESSION="ai-fast"
fi

export WINDOW_TITLE="$TMUXP_SESSION"
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
tmux kill-session -t $TMUXP_SESSION 2>/dev/null || true

alacritty \
  --working-directory ~/.local/state/llm \
  -o font.size=13 \
  --title "$WINDOW_TITLE" \
  --command ~/.nix-profile/bin/zsh -lc "tmuxp load $TMUXP_SESSION"