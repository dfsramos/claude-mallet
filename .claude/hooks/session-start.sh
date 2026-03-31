#!/bin/bash
# Session startup hook: injects MOTD, session ID, project memory, and update check.

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

# Show MOTD if framework.json exists
FRAMEWORK_JSON="${CLAUDE_PROJECT_DIR}/.claude/framework.json"
if [ -f "$FRAMEWORK_JSON" ] && command -v jq &> /dev/null; then
  REPO=$(jq -r '.repo // empty' "$FRAMEWORK_JSON" 2>/dev/null)
  LOCAL_HASH=$(jq -r '.version // empty' "$FRAMEWORK_JSON" 2>/dev/null)
  INSTALLED_AT=$(jq -r '.installed_at // empty' "$FRAMEWORK_JSON" 2>/dev/null)

  if [ -n "$REPO" ] && [ -n "$LOCAL_HASH" ]; then
    SHORT_HASH=$(echo "$LOCAL_HASH" | cut -c1-7)
    UPDATE_LINE=""

    # Check for updates
    if command -v gh &> /dev/null; then
      LATEST_INFO=$(gh api "repos/${REPO}/commits/HEAD" --jq '{sha: .sha, date: .commit.committer.date}' 2>/dev/null)
      if [ -n "$LATEST_INFO" ]; then
        LATEST_HASH=$(echo "$LATEST_INFO" | jq -r '.sha' 2>/dev/null)
        LATEST_DATE=$(echo "$LATEST_INFO" | jq -r '.date' 2>/dev/null | cut -c1-10)
        if [ -n "$LATEST_HASH" ] && [ "$LOCAL_HASH" != "$LATEST_HASH" ]; then
          LATEST_SHORT=$(echo "$LATEST_HASH" | cut -c1-7)
          UPDATE_LINE="  Update:    ${LATEST_SHORT} (${LATEST_DATE}) available — say \"update the framework\""
        fi
      fi
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  AI Framework"
    echo "  Version:   ${SHORT_HASH}  ·  installed ${INSTALLED_AT}"
    echo "  Repo:      https://github.com/${REPO}"
    if [ -n "$UPDATE_LINE" ]; then
      echo "$UPDATE_LINE"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi
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
