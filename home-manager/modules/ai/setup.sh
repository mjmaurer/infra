#!/usr/bin/env bash

if [ -d .git ]; then
    # Create common AI directories
    mkdir -p .devdata/.ai
    mkdir -p .ai

    # Copy AGENTS.md template if it doesn't exist
    if [ ! -f ./AGENTS.md ]; then
        if [ -f $XDG_CONFIG_HOME/ai/AGENTS.md ]; then
            echo "Copying $XDG_CONFIG_HOME/ai/AGENTS.md to AGENTS.md"
            # AGENTS.md is source controlled
            cp -p $XDG_CONFIG_HOME/ai/AGENTS.md AGENTS.md
            chmod 644 AGENTS.md
        else
            echo "$XDG_CONFIG_HOME/ai/AGENTS.md not found, skipping copy."
        fi
    fi

    # Copy AI_README template if it doesn't exist
    if [ ! -f ./AI_README.md ]; then
        if [ -f $XDG_DATA_HOME/AI_README_TMPL.md ]; then
            echo "Copying $XDG_DATA_HOME/AI_README_TMPL.md to AI_README.md"
            # AI_README.md is source controlled
            cp -p $XDG_DATA_HOME/AI_README_TMPL.md AI_README.md
            chmod 644 AI_README.md
        else
            echo "$XDG_DATA_HOME/AI_README_TMPL.md not found, skipping copy."
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