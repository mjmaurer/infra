#!/usr/bin/env zsh

# This script is used to generate a commit message using aichat

set -euo pipefail

# Get the diff of staged changes
DIFF=$(git diff --cached)

if [[ -z "$DIFF" ]]; then
    echo "No staged changes found" >&2
    exit 1
fi

PROMPT="Generate a descriptive but concise git commit message based on these staged changes. It should briefly explain the changes. Follow the conventional commits specification. Here are the changes:

$DIFF

Format the response as a commit message, without quotes or explanations."

COMMIT_MSG=$(echo "$PROMPT" | aichat)

git commit -e -m "$COMMIT_MSG"
