#!/usr/bin/env zsh

# This script is used to generate a commit message using aichat

set -euo pipefail

# Get the diff of staged changes
DIFF=$(git diff --cached)

if [[ -z "$DIFF" ]]; then
    echo "No staged changes found" >&2
    exit 1
fi

PROMPT="Generate a descriptive but concise git commit message based on these staged git changes. It should briefly explain the changes. Follow the conventional commits specification (<type>[optional scope]: <description>). Only output the message, and do not include the changes in the message. If there aren't many changes, keep the message short. Here are the changes:

$DIFF

Format the response as a conventional commit message, without quotes or explanations."

COMMIT_MSG=$(echo "$PROMPT" | llm -o thinking_budget 0)

ykman_output_and_error=$(ykman list -r 2>&1)
ykman_exit_status=$?

# Check for error conditions
if [[ $ykman_exit_status -ne 0 ]] || \
   [[ -z "$ykman_output_and_error" ]] || \
   echo "$ykman_output_and_error" | grep -q "ERROR"; then
  no_yk_or_error=true
else
  no_yk_or_error=false
fi

if [[ "$no_yk_or_error" == "true" ]]; then
  git commit --no-gpg-sign -e -m "$COMMIT_MSG" "$@"
else
  git commit -e -m "$COMMIT_MSG" "$@"
fi
