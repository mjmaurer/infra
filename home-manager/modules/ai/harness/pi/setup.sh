#!/usr/bin/env bash

if [ -d .git ]; then
    mkdir -p .ai/.pi

    # Create root symlink .pi -> .ai/.pi if it doesn't exist
    if [ ! -e .pi ]; then
        ln -s .ai/.pi .pi
    fi

    if [ -f ~/.config/pi/repo-config-nix/settings.json ] && [ ! -f ./.ai/.pi/settings.json ]; then
        echo "Copying ~/.config/pi/repo-config-nix/settings.json to .ai/.pi/settings.json"
        cp -p ~/.config/pi/repo-config-nix/settings.json ./.ai/.pi/settings.json
        chmod 644 ./.ai/.pi/settings.json
    fi
fi
