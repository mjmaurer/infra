---
name: codex-cli
description: Use when the user asks to run Codex / Codex CLI.
allowed-tools: Bash(codex exec --sandbox read-only *), Bash(sed *)

context: fork
---

# Codex Skill Guide

This skill is strictly for getting output directly from the codex CLI command.

## Running a Task

Run the command with the exact prompt you received with the following options in the specified order:

```
codex exec --sandbox read-only --model gpt-5.2 --config model_reasoning_effort=xhigh --ask-for-approval never --skip-git-repo-check YOUR_PROMPT
```

**IMPORTANT**: By default, append `2>/dev/null` to all `codex exec` commands to suppress thinking tokens (stderr). Only show stderr if the user explicitly requests to see thinking tokens or if debugging is needed.

Run the command, capture stdout/stderr (filtered as appropriate), and return the output to the user.

## Following Up

Do the following after the command depending on the exit code

### On Success 

Give the codex output exactly as it was returned. Do not modify it in any way. Do not give any commentary.

### On Error 

Stop and report failures whenever the codex command exits non-zero; request direction before retrying.