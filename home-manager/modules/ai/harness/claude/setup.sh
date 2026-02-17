#!/usr/bin/env bash

if [ -d .git ]; then
    mkdir -p .ai/.claude

    # Migrate existing .claude directory to .ai/.claude
    if [ -d .claude ] && [ ! -L .claude ]; then
        echo "Migrating .claude/ contents to .ai/.claude/"
        cp -a .claude/. .ai/.claude/
        rm -rf .claude
    fi

    # Create root symlink .claude -> .ai/.claude if it doesn't exist
    if [ ! -e .claude ]; then
        ln -s .ai/.claude .claude
    fi

    # Create symlink .ai/.claude/CLAUDE.md -> ../../AGENTS.md if AGENTS.md exists and CLAUDE.md doesn't
    if [ -f ./AGENTS.md ] && [ ! -f ./.ai/.claude/CLAUDE.md ]; then
        echo "Creating symlink .ai/.claude/CLAUDE.md -> ../../AGENTS.md"
        ln -s ../../AGENTS.md ./.ai/.claude/CLAUDE.md
    fi

    if [ -f ~/.claude/repo-config-nix/settings-tmpl.json ] && [ ! -f ./.ai/.claude/settings.json ]; then
        echo "Copying ~/.claude/repo-config-nix/settings-tmpl.json to .ai/.claude/settings.json"
        cp -p ~/.claude/repo-config-nix/settings-tmpl.json ./.ai/.claude/settings.json
        chmod 644 ./.ai/.claude/settings.json
    fi
fi
