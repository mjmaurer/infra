if [ -d .git ]; then
    mkdir -p .devdata/.aider
    touch .devdata/PROJECT.md
    touch .devdata/CONVENTIONS.md

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