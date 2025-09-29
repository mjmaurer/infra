#!/usr/bin/env zsh

# This script is used to generate a commit message using aichat

set -euo pipefail

if ! gpg_output_and_error=$(gpg --card-status 2>&1); then
  # Try to warm up the GPG agent
  echo "First 'gpg --card-status' failed" >&2
fi

# Get the diff of staged changes
DIFF=$(git diff --cached)

if [[ -z "$DIFF" ]]; then
    echo "No staged changes found" >&2
    exit 1
fi

PROMPT="Generate a descriptive but concise git commit message based on these staged git changes. It should briefly explain the changes. Follow the conventional commits specification (<type>[optional scope]: <description>). Only output the message, and do not include the changes in the message. If there aren't many changes, keep the message short. Here are the changes:

$DIFF

Format the response as a conventional commit message, without quotes or explanations."

COMMIT_MSG=$(echo "$PROMPT" | llm --no-log)

if gpg_output_and_error=$(gpg --card-status 2>&1); then
  no_gpg_or_error=false
else
  echo "'gpg --card-status' failed with output: $gpg_output_and_error" >&2
  echo "Adding --no-gpg-sign." >&2
  no_gpg_or_error=true
fi

if [[ "$no_gpg_or_error" == "true" ]]; then
  git commit --no-gpg-sign -e -m "$COMMIT_MSG" "$@"
else
  git commit -e -m "$COMMIT_MSG" "$@"
fi
