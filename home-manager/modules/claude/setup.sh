if [ -d .git ]; then
    mkdir -p .devdata/.claude
    mkdir -p .claude

    if [ ! -f ./AI_README.md ]; then
        if [ -f $XDG_DATA_HOME/AI_README_TMPL.md ]; then
            echo "Copying $XDG_DATA_HOME/AI_README_TMPL.md to AI_README.md"
            # AI_README.md is source controlled
            cp -p $XDG_DATA_HOME/AI_README_TMPL.md AI_README.md
        else
            echo "$XDG_DATA_HOME/AI_README_TMPL.md not found, skipping copy."
        fi
    fi

    if [ ! -f ./CLAUDE.md ]; then
        if [ -f ~/.claude/LOCAL_CLAUDE_TMPL.md ]; then
            echo "Copying ~/.claude/LOCAL_CLAUDE_TMPL.md to .devdata/.claude/CLAUDE.md"
            cp -p ~/.claude/LOCAL_CLAUDE_TMPL.md .devdata/.claude/CLAUDE.md
            echo "Linking .devdata/.claude/CLAUDE.md to CLAUDE.md"
            ln -s .devdata/.claude/CLAUDE.md CLAUDE.md
        else
            echo "~/.claude/LOCAL_CLAUDE_TMPL.md not found, skipping copy."
        fi
    fi

    if [ ! -f ./.claude/settings.json ]; then
        if [ -f ~/.claude/local-settings-tmpl.json ]; then
            echo "Copying ~/.claude/local-settings-tmpl.json to .devdata/.claude/settings.json"
            cp -p ~/.claude/local-settings-tmpl.json .devdata/.claude/settings.json
            echo "Linking .devdata/.claude/settings.json to .claude/settings.json"
            ln -s .devdata/.claude/settings.json .claude/settings.json
        else
            echo "~/.claude/local-settings-tmpl.json not found, skipping copy."
        fi
    fi
fi