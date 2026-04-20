#!/bin/bash
# Session startup hook:
#   1. Injects project memory into context (if present).
#   2. Checks for a framework update and surfaces it as a notice (if available).

# ── Project memory ──────────────────────────────────────────────────────────

MEMORY_FILE="${CLAUDE_PROJECT_DIR}/.claude/project/memory.md"
if [ -f "$MEMORY_FILE" ]; then
  echo "--- Project Memory ---"
  cat "$MEMORY_FILE"
  echo "--- End Project Memory ---"
fi

# ── Framework update check ──────────────────────────────────────────────────

FRAMEWORK_JSON="${CLAUDE_PROJECT_DIR}/.claude/framework.json"
if [ -f "$FRAMEWORK_JSON" ] && command -v curl >/dev/null && command -v jq >/dev/null; then
  LOCAL_HASH=$(jq -r '.version // empty' "$FRAMEWORK_JSON")
  REPO=$(jq -r '.repo // empty' "$FRAMEWORK_JSON")

  if [ -n "$LOCAL_HASH" ] && [ -n "$REPO" ]; then
    BRANCH=$(curl -sf --max-time 3 "https://api.github.com/repos/${REPO}" | jq -r '.default_branch // empty')

    if [ -n "$BRANCH" ]; then
      LATEST=$(curl -sf --max-time 3 "https://api.github.com/repos/${REPO}/commits/${BRANCH}")
      LATEST_HASH=$(echo "$LATEST" | jq -r '.sha // empty')
      LATEST_DATE=$(echo "$LATEST" | jq -r '.commit.committer.date // empty' | cut -c1-10)

      if [ -n "$LATEST_HASH" ] && [ "$LOCAL_HASH" != "$LATEST_HASH" ]; then
        echo "--- Framework Update Available ---"
        echo "Current: ${LOCAL_HASH:0:7}"
        echo "Latest:  ${LATEST_HASH:0:7} (${LATEST_DATE})"
        echo "Mention this to the user and offer to run the update skill."
        echo "--- End Framework Update Available ---"
      fi
    fi
  fi
fi

exit 0
