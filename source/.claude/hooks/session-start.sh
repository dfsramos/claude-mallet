#!/bin/bash
# Session startup hook: injects session ID and project memory.

# Read session ID from hook input JSON
SESSION_ID=$(jq -r '.session_id // empty')

if [ -z "$SESSION_ID" ]; then
  echo "Warning: could not read session_id from hook input" >&2
  exit 0
fi

# Persist session ID as environment variable
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "SESSION_ID=${SESSION_ID}" >> "$CLAUDE_ENV_FILE"
fi

# Always inject session ID
echo "Session ID: ${SESSION_ID}"

# Inject project memory if it exists
MEMORY_FILE="${CLAUDE_PROJECT_DIR}/.claude/project/memory.md"
if [ -f "$MEMORY_FILE" ]; then
  echo ""
  echo "--- Project Memory ---"
  cat "$MEMORY_FILE"
  echo "--- End Project Memory ---"
fi

exit 0
