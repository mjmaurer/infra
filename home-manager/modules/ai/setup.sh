#!/usr/bin/env bash

if [ -d .git ]; then
    # Copy AGENTS.md template if it doesn't exist
    if [ ! -f ./AGENTS.md ]; then
        if [ -f $XDG_CONFIG_HOME/ai/repo-config-nix/AGENTS.md ]; then
            echo "Copying $XDG_CONFIG_HOME/ai/repo-config-nix/AGENTS.md to AGENTS.md"
            cp -p $XDG_CONFIG_HOME/ai/repo-config-nix/AGENTS.md AGENTS.md
            chmod 644 AGENTS.md
        else
            echo "$XDG_CONFIG_HOME/ai/repo-config-nix/AGENTS.md not found, skipping copy."
        fi
    fi

    # Call agent-specific setup scripts if they exist
    if command -v claude-agent-setup &> /dev/null; then
        claude-agent-setup
    fi

    if command -v aider-agent-setup &> /dev/null; then
        aider-agent-setup
    fi
fi