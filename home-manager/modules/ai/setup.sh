#!/usr/bin/env bash

if [ -d .git ]; then
    # Create shared .ai directory and its .gitignore
    mkdir -p .ai
    if [ ! -f .ai/.gitignore ]; then
        cat > .ai/.gitignore << 'GITIGNORE'
.claude
.codex
.opencode
GITIGNORE
    fi

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

    if command -v codex-agent-setup &> /dev/null; then
        codex-agent-setup
    fi

    if command -v opencode-agent-setup &> /dev/null; then
        opencode-agent-setup
    fi
fi
