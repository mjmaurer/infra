set -euo pipefail

SEARCH_ROOT="${LLM_SESSION_ROOT:-$HOME/.local/state/llm/sessions}"
MODE="o"  # default: original prompt.md only

# Parse flags
while getopts ":opra" opt; do
    case "$opt" in
    o) MODE="o" ;;  # root prompt.md only
    p) MODE="p" ;;  # all prompts (root + agent *_prompt.md)
    r) MODE="r" ;;  # responses (*_response.md)
    a) MODE="a" ;;  # everything (*.md)
    \?) echo "Unknown option: -$OPTARG" >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))

QUERY="${*:-}"
if [ -z "$QUERY" ]; then
    QUERY="^"  # match everything if empty query
fi

case "$MODE" in
    o) RG_GLOBS=(--glob '**/prompt.md' --glob '!**/[0-9][0-9]_*.md') ;;
    p) RG_GLOBS=(--glob '**/prompt.md' --glob '**/[0-9][0-9]_prompt.md') ;;
    r) RG_GLOBS=(--glob '**/[0-9][0-9]_response.md') ;;
    a) RG_GLOBS=(--glob '**/*.md') ;;
esac

echo "Searching in: $SEARCH_ROOT"
echo "Using mode: $MODE"
echo "Using globs: ${RG_GLOBS[*]}"
echo "Using query: '$QUERY'"

# Run search -> select with fzf-tmux
SEL="$(
    rg --line-number --no-heading --color=always "${RG_GLOBS[@]}" -- "$QUERY" "$SEARCH_ROOT" \
    | fzf-tmux -p 90%,90% --ansi --no-sort --query "$QUERY" \
    | sed 's/:.*//'
)" || true

if [ -z "${SEL:-}" ]; then
    echo "No selection."
    exit 0
fi

SEL_BASENAME="$(basename "$SEL")"
if [ "$SEL_BASENAME" = "prompt.md" ]; then
    LLM_SESSION_DIR="$(dirname "$SEL")"
else
    LLM_SESSION_DIR="$(dirname "$(dirname "$SEL")")"
fi

SESSION_DIRNAME="$(basename "$LLM_SESSION_DIR")"
SESSION_TYPE="$(printf '%s\n' "$SESSION_DIRNAME" | awk -F'_' '{print $2}')"
case " $SESSION_TYPE " in
    " ai " | " ai-code " | " ai-fast ") ;;  # allowed
    *) SESSION_TYPE="ai" ;;
esac

AI_CMD=""
if [ -f "$LLM_SESSION_DIR/prompt.md" ]; then
    AI_CMD="$(cat "$LLM_SESSION_DIR/prompt.md")"
fi

# Fast load: no staggered sleeps
export TMUXP_AI_STUTTER="0"

# Optional: close any existing window with same title (macOS Aerospace)
WINDOW_TITLE="$SESSION_TYPE"
if command -v aerospace >/dev/null 2>&1; then
    WINDOW_ID="$(
    aerospace list-windows --all --json \
        | jq -r --arg title "$WINDOW_TITLE" \
        '.[] | select(."app-name" == "alacritty" and ."window-title" == $title) | ."window-id"' \
        | xargs
    )"
    if [ -n "${WINDOW_ID// /}" ]; then
        aerospace close --window-id "$WINDOW_ID" || true
    fi
fi

# Build tmuxp load command; quote AI_CMD safely
AI_CMD_Q="$(printf '%q' "$AI_CMD")"
TMUXP_CMD="unset TMUX; \
tmux kill-session -t '$SESSION_TYPE' 2>/dev/null || true; \
LLM_SESSION_DIR='$LLM_SESSION_DIR' TMUXP_AI_STUTTER=0 AI_CMD=$AI_CMD_Q tmuxp load '$SESSION_TYPE'"

alacritty \
    --working-directory "$HOME/.local/state/llm" \
    -o font.size=13 \
    --title "$SESSION_TYPE" \
    --command ~/.nix-profile/bin/zsh -lc "$TMUXP_CMD" \
    >/dev/null 2>&1 </dev/null &