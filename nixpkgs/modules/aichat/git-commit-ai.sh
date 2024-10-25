#!/usr/bin/env zsh

set -euo pipefail

# Get the diff of staged changes
DIFF=$(git diff --cached)

if [[ -z "$DIFF" ]]; then
    echo "No staged changes found" >&2
    exit 1
fi

# Create a prompt that describes what we want
PROMPT="Generate a concise and descriptive git commit message based on these staged changes. Follow the conventional commits specification. Here are the changes:

$DIFF

Format the response as a commit message, without quotes or explanations."

# Generate the commit message using aichat
COMMIT_MSG=$(echo "$PROMPT" | aichat)

# Start git commit with the generated message
git commit -e -m "$COMMIT_MSG"
