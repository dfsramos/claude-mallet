#!/bin/bash
# PreToolUse hook: blocks Write calls on files that already exist.
# CLAUDE.md requires Edit for existing files — Write is for new files only.
# Edit sends only the diff; Write re-sends the full content, doubling output tokens.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

if [ "$TOOL" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    echo "[write-guard] '$FILE_PATH' already exists. Use Edit instead — it sends only the changed lines and costs fewer tokens. Write is reserved for files that do not yet exist (CLAUDE.md)."
    exit 2
  fi
fi

exit 0
