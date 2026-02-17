#!/usr/bin/env bash

if [ -d .git ]; then
    mkdir -p .ai/.opencode

    # Create root symlink .opencode -> .ai/.opencode if it doesn't exist
    if [ ! -e .opencode ]; then
        ln -s .ai/.opencode .opencode
    fi

    if [ -f ~/.config/opencode/repo-config-nix/config-tmpl.json ] && [ ! -f ./.ai/.opencode/config.json ]; then
        echo "Copying ~/.config/opencode/repo-config-nix/config-tmpl.json to .ai/.opencode/config.json"
        cp -p ~/.config/opencode/repo-config-nix/config-tmpl.json ./.ai/.opencode/config.json
        chmod 644 ./.ai/.opencode/config.json
    fi
fi
