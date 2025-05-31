# Usage: Type `aicmd "your prompt"` and press Enter.
# The command line will be replaced with the output of `llm cmdcomp`.
llmcmd() {
  if [ -z "$*" ]; then
    echo "Usage: aicmd \"your prompt here\"" >&2
    # Update buffer to show the error or the incomplete command
    BUFFER="aicmd: missing prompt argument"
    CURSOR=${#BUFFER}
    return 1
  fi

  local user_prompt="$*"
  local result
  # Save the command line as it was typed by the user (e.g., aicmd "foo")
  # This allows us to restore it if llm cmdcomp fails.
  local initial_buffer_content=$BUFFER

  result=$(llm cmdcomp "$user_prompt")

  # Check if llm cmdcomp succeeded (exit status 0) and produced non-empty output
  if [ $? -eq 0 ] && [ -n "$result" ]; then
    BUFFER="$result"      # Set the command line buffer to the new command
    CURSOR=${#BUFFER}     # Move the cursor to the end of the new command
    print -z -- "$result"
  else
    echo "aicmd: 'llm cmdcomp' failed or returned an empty result for prompt: \"$user_prompt\"" >&2
    # Restore the buffer to what the user originally typed, so they can edit or retry.
    BUFFER="$initial_buffer_content"
    CURSOR=${#BUFFER}
    # return a non-zero status to indicate aicmd itself had an issue (though it ran)
    return 1
  fi
}
