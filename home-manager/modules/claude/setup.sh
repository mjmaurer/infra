if [ -d .git ]; then
    mkdir -p .devdata

    if [ ! -f ./PROJECT.md ]; then
        if [ -f $XDG_DATA_HOME/PROJECT_TMPL.md ]; then
            echo "Copying $XDG_DATA_HOME/PROJECT_TMPL.md to PROJECT.md"
            cp $XDG_DATA_HOME/PROJECT_TMPL.md ./PROJECT.md
        else
            echo "$XDG_DATA_HOME/PROJECT_TMPL.md not found, skipping copy."
        fi
    fi

    if [ ! -f ./CLAUDE.md ]; then
        if [ -f ~/.claude/LOCAL_CLAUDE_TMPL.md ]; then
            echo "Copying ~/.claude/LOCAL_CLAUDE_TMPL.md to CLAUDE.md"
            cp ~/.claude/LOCAL_CLAUDE_TMPL.md ./CLAUDE.md
        else
            echo "~/.claude/LOCAL_CLAUDE_TMPL.md not found, skipping copy."
        fi
    fi