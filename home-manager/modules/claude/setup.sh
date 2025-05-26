if [ -d .git ]; then
    mkdir -p .devdata/ai/claude
    mkdir -p .claude

    if [ ! -f ./PROJECT.md ]; then
        if [ -f $XDG_DATA_HOME/PROJECT_TMPL.md ]; then
            echo "Copying $XDG_DATA_HOME/PROJECT_TMPL.md to PROJECT.md"
            # PROJECT.md is source controlled
            cp -p $XDG_DATA_HOME/PROJECT_TMPL.md PROJECT.md
        else
            echo "$XDG_DATA_HOME/PROJECT_TMPL.md not found, skipping copy."
        fi
    fi

    if [ ! -f ./CLAUDE.md ]; then
        if [ -f ~/.claude/LOCAL_CLAUDE_TMPL.md ]; then
            echo "Copying ~/.claude/LOCAL_CLAUDE_TMPL.md to .devdata/CLAUDE.md"
            cp -p ~/.claude/LOCAL_CLAUDE_TMPL.md .devdata/ai/CLAUDE.md
            echo "Linking .devdata/ai/CLAUDE.md to CLAUDE.md"
            ln -s .devdata/ai/CLAUDE.md CLAUDE.md
        else
            echo "~/.claude/LOCAL_CLAUDE_TMPL.md not found, skipping copy."
        fi
    fi

    if [ ! -f ./.claude/settings.json ]; then
        if [ -f ~/.claude/local-settings-tmpl.json ]; then
            echo "Copying ~/.claude/local-settings-tmpl.json to .devdata/ai/claude/settings.json"
            cp -p ~/.claude/local-settings-tmpl.json .devdata/ai/claude/settings.json
            echo "Linking .devdata/ai/claude/settings.json to .claude/settings.json"
            ln -s .devdata/ai/claude/settings.json .claude/settings.json
        else
            echo "~/.claude/local-settings-tmpl.json not found, skipping copy."
        fi
    fi
fi