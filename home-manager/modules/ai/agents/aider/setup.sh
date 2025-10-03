#!/usr/bin/env bash

if [ -d .git ]; then
    mkdir -p .devdata/.aider

    # Create symlink RULES.md -> AGENTS.md if AGENTS.md exists and RULES.md doesn't
    if [ -f ./AGENTS.md ] && [ ! -f ./RULES.md ]; then
        echo "Creating symlink RULES.md -> AGENTS.md"
        ln -s AGENTS.md RULES.md
    fi

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