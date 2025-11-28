export PATH="$PATH:/opt/homebrew/bin:$HOME/.nix-profile/bin"

if [[ "$@" == ". "* ]]; then
  echo "Custom session mode"
  args="${@:2}"
  first="${args%% *}"
  if [[ "$first" == ai || "$first" == ai-* ]]; then
    export TMUXP_SESSION="$first"
  else
    export TMUXP_SESSION="ai-$first"
  fi
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

# Validate against TMUXP_AI_SESSIONS if provided
if [ -n "${TMUXP_AI_SESSIONS:-}" ]; then
  case " ${TMUXP_AI_SESSIONS} " in
    *" ${TMUXP_SESSION} "*) ;;  # ok
    *)
      echo "Unknown tmuxp session '${TMUXP_SESSION}'. Allowed: ${TMUXP_AI_SESSIONS}" >&2
      exit 2
      ;;
  esac
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

if command -v aerospace >/dev/null 2>&1 && [[ -n "${WINDOW_ID// /}" ]]; then
  echo "closing $WINDOW_ID"
  aerospace close --window-id "$WINDOW_ID"
fi

alacritty \
  --working-directory ~/.local/state/llm \
  -o font.size=13 \
  --title "$WINDOW_TITLE" \
  --command ~/.nix-profile/bin/zsh -lc "unset TMUX; tmux kill-session -t '$TMUXP_SESSION' 2>/dev/null || true; tmuxp load '$TMUXP_SESSION'"
