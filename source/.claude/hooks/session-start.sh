#!/bin/bash
# Session startup hook: injects project memory into context.

MEMORY_FILE="${CLAUDE_PROJECT_DIR}/.claude/project/memory.md"
if [ -f "$MEMORY_FILE" ]; then
  echo "--- Project Memory ---"
  cat "$MEMORY_FILE"
  echo "--- End Project Memory ---"
fi

exit 0
