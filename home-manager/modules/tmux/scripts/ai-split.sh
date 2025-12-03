export PATH="$PATH:/opt/homebrew/bin:$HOME/.nix-profile/bin"

# Source Nix Home Manager session variables
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

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
  export AI_RECORD_SESSION="true"
elif [[ "$@" == "f "* ]]; then
  echo "Fast mode"
  export AI_CMD="${@:2}"
  export TMUXP_SESSION="ai-fast"
  export AI_RECORD_SESSION="false"
elif [[ "$@" == "c "* ]]; then
  echo "Code mode"
  export AI_CMD="${@:2}"
  export TMUXP_SESSION="ai-code"
  export AI_RECORD_SESSION="false"
else
  echo "Thinking mode"
  export AI_CMD="$@"
  export TMUXP_SESSION="ai"
  export AI_RECORD_SESSION="true"
fi

# Decide whether to record this session
if [ "$(printf '%s' "${AI_RECORD_SESSION:-true}" | tr '[:upper:]' '[:lower:]')" = "false" ]; then
  # Recording disabled: no slug, no directory, empty session dir
  export LLM_SESSION_DIR=""
else
  # Generate summary slug first (used in session directory name)
  SLUG="$(
    llm \
      -m openrouter/openai/gpt-oss-120b \
      -o reasoning_effort low \
      -o provider '{"order":["cerebras"],"allow_fallbacks": true, "sort":"throughput"}' \
      "Generate a concise 2-4 word kebab-case ASCII-only slug summarizing this prompt. Output ONLY the slug, no quotes or punctuation:

Prompt:
$AI_CMD"
  )"

  # Sanitize: lowercase, keep [a-z0-9-], collapse dashes, trim edges
  SLUG="$(printf '%s' "$SLUG" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9-' '-' \
    | sed -E 's/^-+//; s/-+$//; s/-+/-/g')"

  # Fallback if slug is empty
  if [ -z "$SLUG" ]; then
    SLUG="session"
  fi

  # Create per-session directory with TIMESTAMP_SLUG
  TIMESTAMP="$(date +%Y-%m-%d-%H%M%S)"
  SESSION_ROOT="${LLM_SESSION_ROOT:-$HOME/.local/state/llm/sessions}"
  CURRENT_SESSION_DIR="$SESSION_ROOT/${TIMESTAMP}_${TMUXP_SESSION}_${SLUG}"
  mkdir -p "$CURRENT_SESSION_DIR"

  # Save initial prompt for reference
  printf '%s\n' "$AI_CMD" > "$CURRENT_SESSION_DIR/prompt.md"

  # Expose to panes
  export LLM_SESSION_DIR="$CURRENT_SESSION_DIR"
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

# Set the environment variable globally on the tmux server so the new session inherits it.
# We must ensure the server is running first.
TMUXP_CMD="unset TMUX; \
tmux kill-session -t '$TMUXP_SESSION' 2>/dev/null || true; \
LLM_SESSION_DIR='$LLM_SESSION_DIR' tmuxp load '$TMUXP_SESSION'"

alacritty \
  --working-directory "$HOME/.local/state/llm" \
  -o font.size=13 \
  --title "$WINDOW_TITLE" \
  --command ~/.nix-profile/bin/zsh -lc "$TMUXP_CMD"
