#!/usr/bin/env bash

if [ -d .git ]; then
    mkdir -p .claude

    # Create symlink .claude/CLAUDE.md -> AGENTS.md if AGENTS.md exists and CLAUDE.md doesn't
    if [ -f ./AGENTS.md ] && [ ! -f ./.claude/CLAUDE.md ]; then
        echo "Creating symlink ./claude/CLAUDE.md -> AGENTS.md"
        ln -s AGENTS.md ./.claude/CLAUDE.md
    fi

    if [ -f ~/.claude/repo-config-nix/settings-tmpl.json ] && [ ! -f ./.claude/settings.json ]; then
        echo "Copying ~/.claude/repo-config-nix/settings-tmpl.json to .claude/settings.json"
        cp -p ~/.claude/repo-config-nix/settings-tmpl.json .claude/settings.json
    fi

    # if [ -f ~/.config/ai/repo-config-nix/mcp.json ] && [ ! -f ./.mcp.json ]; then
    #     echo "Creating symlink .mcp.json -> ~/.config/ai/repo-config-nix/mcp.json"
    #     ln -s ~/.config/ai/repo-config-nix/mcp.json .mcp.json
    # fi
fi