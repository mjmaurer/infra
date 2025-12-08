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

# Build candidate list: files matching query, shown relative to SEARCH_ROOT
# Use substring logic (not regex) so special chars in SEARCH_ROOT don't break trimming,
# and handle optional trailing slash on SEARCH_ROOT.
CANDIDATES="$(
  rg -l "${RG_GLOBS[@]}" -- "$QUERY" "$SEARCH_ROOT" 2>/dev/null \
  | awk -v root="$SEARCH_ROOT" '{
      s=$0;
      n=length(root);
      if (substr(s,1,n)==root) {
        if (substr(s,n+1,1)=="/") print substr(s,n+2);
        else print substr(s,n+1);
      } else {
        print s;
      }
    }' \
  | sed '/^$/d' \
  | sort -ru
)"

# Build display lines: "<label-without-leading-date>	<original-relative-path>"
DISPLAY_CANDIDATES="$(
  printf '%s\n' "$CANDIDATES" \
  | awk -F/ '{
      orig=$0;
      origFirst=$1;
      first=$1;
      # Strip leading date/time from first segment:
      # - Date: YYYY[-_ ]?MM[-_ ]?DD
      # - Optional time: [-_ ]?HHMMSS
      # - Optional trailing separator after date/time
      gsub(/^[0-9]{4}[-_ ]?[01][0-9][-_ ]?[0-3][0-9]([-_ ]?[0-2][0-9][0-5][0-9][0-5][0-9])?[-_ ]?/, "", first);
      if (first == "") first = origFirst;  # fallback if dir is only a date
      $1=first;
      disp=$1;
      for (i=2;i<=NF;i++) disp=disp "/" $i;
      print disp "\t" orig;
    }'
)"

# --preview "cat \"${SEARCH_ROOT}/{}\"" \
# Split-screen fzf: left = relative filename list, right = streamdown preview
SEL_LINE="$(
  printf '%s\n' "$DISPLAY_CANDIDATES" \
  | fzf --ansi \
        --no-sort \
        --query "$QUERY" \
        --delimiter '\t' \
        --with-nth=1 \
        --preview 'sh -c '"'"'sd "$1/$2"'"'"' _ '"$SEARCH_ROOT"' {2}' \
        --preview-window=right,55%,wrap \
        --height=100% \
        --reverse \
        --border \
        --prompt 'ai-recall> '
)" || true
SEL_REL="$(printf '%s\n' "${SEL_LINE:-}" | awk -F'\t' '{print $2}')"

if [ -z "${SEL_REL:-}" ]; then
    echo "No selection."
    exit 0
fi

SEL="${SEARCH_ROOT}/${SEL_REL}"
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
