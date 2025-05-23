if [ -d .git ]; then
    mkdir -p .devdata
    touch .devdata/PROJECT.md
    touch .devdata/CONVENTIONS.md

    if [ -f ~/.claude/LOCAL_CLAUDE.md ]; then
        cp ~/.claude/LOCAL_CLAUDE.md ./CLAUDE.md
    fi
fi