if [ -d .git ]; then
    mkdir -p .devdata/.aider
    # Just call claude for PROJECT.md / CLAUDE.md
    claude-setup

    if [ -f ~/.config/aider/.aiderinclude ] && [ ! -f .devdata/.aiderinclude ]; then
        cp ~/.config/aider/.aiderinclude .devdata/.aiderinclude
    fi

    > .devdata/.aiderignore
    if [ -f .gitignore ]; then
        cat .gitignore >> .devdata/.aiderignore
    fi
    if [ -f .devdata/.aiderinclude ]; then
        cat .devdata/.aiderinclude >> .devdata/.aiderignore
    fi
fi