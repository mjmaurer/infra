if [ -d .git ]; then
    mkdir -p .devdata/.aider
    # Just call claude for AI_README.md / CLAUDE.md
    claude-setup

    if [ -f ~/.config/aider/.aiderinclude ] && [ ! -f .devdata/.aider/.aiderinclude ]; then
        cp ~/.config/aider/.aiderinclude .devdata/.aider/.aiderinclude
    fi

    > .devdata/.aider/.aiderignore
    if [ -f .gitignore ]; then
        cat .gitignore >> .devdata/.aider/.aiderignore
    fi
    if [ -f .devdata/.aider/.aiderinclude ]; then
        cat .devdata/.aider/.aiderinclude >> .devdata/.aider/.aiderignore
    fi
fi