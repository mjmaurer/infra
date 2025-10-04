#!/usr/bin/env bash

if [ -d .git ]; then
    mkdir -p .devdata/.claude
    mkdir -p .claude

    # Create symlink CLAUDE.md -> AGENTS.md if AGENTS.md exists and CLAUDE.md doesn't
    if [ -f ./AGENTS.md ] && [ ! -f ./CLAUDE.md ]; then
        echo "Creating symlink CLAUDE.md -> AGENTS.md"
        ln -s AGENTS.md CLAUDE.md
    fi

    if [ ! -f ./.claude/settings.json ]; then
        if [ -f ~/.claude/local-settings-tmpl.json ]; then
            echo "Copying ~/.claude/local-settings-tmpl.json to .devdata/.claude/settings.json"
            cp -p ~/.claude/local-settings-tmpl.json .devdata/.claude/settings.json
            echo "Linking .devdata/.claude/settings.json to .claude/settings.json"
            # Create a RELATIVE symlink to the settings file
            ln -s ../.devdata/.claude/settings.json .claude/settings.json
            chmod 644 .claude/settings.json
        else
            echo "~/.claude/local-settings-tmpl.json not found, skipping copy."
        fi
    fi

    if [ ! -f ./mcp.json ] && [ -f ~/.config/ai/mcp.json ]; then
        echo "Creating symlink .mcp.json -> ~/.config/ai/mcp.json"
        ln -s ~/.config/ai/mcp.json .mcp.json
    fi
fi