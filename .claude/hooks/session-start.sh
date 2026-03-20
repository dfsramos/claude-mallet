#!/bin/bash
# Reads the Claude session ID from the hook input JSON (stdin),
# persists it as an environment variable, and injects it into Claude's context.

SESSION_ID=$(jq -r '.session_id // empty')

if [ -z "$SESSION_ID" ]; then
  echo "Warning: could not read session_id from hook input" >&2
  exit 0
fi

# Persist as environment variable for this session and all subsequent Bash calls
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "SESSION_ID=${SESSION_ID}" >> "$CLAUDE_ENV_FILE"
fi

# Inject into Claude's context via stdout (SessionStart hook behaviour)
echo "Session ID: ${SESSION_ID}"

# Inject project memory if it exists
MEMORY_FILE="${CLAUDE_PROJECT_DIR}/.claude/project/memory.md"
if [ -f "$MEMORY_FILE" ]; then
  echo ""
  echo "--- Project Memory ---"
  cat "$MEMORY_FILE"
  echo "--- End Project Memory ---"
fi

# Check for framework updates
FRAMEWORK_JSON="${CLAUDE_PROJECT_DIR}/.claude/framework.json"
if [ -f "$FRAMEWORK_JSON" ] && command -v gh &> /dev/null && command -v jq &> /dev/null; then
  REPO=$(jq -r '.repo' "$FRAMEWORK_JSON" 2>/dev/null)
  LOCAL_HASH=$(jq -r '.version' "$FRAMEWORK_JSON" 2>/dev/null)
  if [ -n "$REPO" ] && [ -n "$LOCAL_HASH" ] && [ "$REPO" != "null" ] && [ "$LOCAL_HASH" != "null" ]; then
    LATEST_INFO=$(gh api "repos/${REPO}/commits/HEAD" --jq '{sha: .sha, date: .commit.committer.date}' 2>/dev/null)
    if [ -n "$LATEST_INFO" ]; then
      LATEST_HASH=$(echo "$LATEST_INFO" | jq -r '.sha' 2>/dev/null)
      LATEST_DATE=$(echo "$LATEST_INFO" | jq -r '.date' 2>/dev/null | cut -c1-10)
      if [ -n "$LATEST_HASH" ] && [ "$LOCAL_HASH" != "$LATEST_HASH" ]; then
        LOCAL_SHORT=$(echo "$LOCAL_HASH" | cut -c1-7)
        LATEST_SHORT=$(echo "$LATEST_HASH" | cut -c1-7)
        echo ""
        echo "--- Framework Update Available ---"
        echo "Installed: ${LOCAL_SHORT} | Latest: ${LATEST_SHORT} (${LATEST_DATE})"
        echo "To update, say: \"update the framework from https://github.com/${REPO}\""
        echo "--- End Framework Update ---"
      fi
    fi
  fi
fi

exit 0
