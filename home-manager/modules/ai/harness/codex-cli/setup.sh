#!/usr/bin/env bash

if [ -d .git ]; then
    mkdir -p .ai/.codex

    # Create root symlink .codex -> .ai/.codex if it doesn't exist
    if [ ! -e .codex ]; then
        ln -s .ai/.codex .codex
    fi

    if [ -f ~/.codex/repo-config-nix/config-tmpl.toml ] && [ ! -f ./.ai/.codex/config.toml ]; then
        echo "Copying ~/.codex/repo-config-nix/config-tmpl.toml to .ai/.codex/config.toml"
        cp -p ~/.codex/repo-config-nix/config-tmpl.toml ./.ai/.codex/config.toml
        chmod 644 ./.ai/.codex/config.toml
    fi
fi
