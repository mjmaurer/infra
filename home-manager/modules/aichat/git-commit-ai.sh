#!/usr/bin/env zsh

# This script is used to generate a commit message using aichat

set -euo pipefail

# Get the diff of staged changes
DIFF=$(git diff --cached)

if [[ -z "$DIFF" ]]; then
    echo "No staged changes found" >&2
    exit 1
fi

PROMPT="Generate a descriptive but concise git commit message based on these staged git changes. It should briefly explain the changes. Follow the conventional commits specification. Only output the message, and do not include the changes in the message. Here are the changes:

$DIFF

Format the response as a commit message, without quotes or explanations."

COMMIT_MSG=$(echo "$PROMPT" | aichat --model gemini:gemini-2.0-flash-exp)

git commit -e -m "$COMMIT_MSG" "$@"
