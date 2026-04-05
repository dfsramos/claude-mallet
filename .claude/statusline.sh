#!/bin/bash
# Statusline: shows AI Framework version and available update.
# Receives Claude Code session JSON via stdin.

input=$(cat)

# Locate framework.json from project dir (env var preferred, JSON fallback)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(echo "$input" | jq -r '.workspace.project_dir // empty' 2>/dev/null)}"
FRAMEWORK_JSON="${PROJECT_DIR}/.claude/framework.json"

[ ! -f "$FRAMEWORK_JSON" ] && exit 0
command -v jq &>/dev/null || exit 0

LOCAL_HASH=$(jq -r '.version // empty' "$FRAMEWORK_JSON")
INSTALLED_AT=$(jq -r '.installed_at // empty' "$FRAMEWORK_JSON")
REPO=$(jq -r '.repo // empty' "$FRAMEWORK_JSON")

[ -z "$LOCAL_HASH" ] && exit 0

SHORT_HASH="${LOCAL_HASH:0:7}"
update_info=""

# Check for updates — cached per installed version (5 min TTL)
if command -v gh &>/dev/null && [ -n "$REPO" ]; then
  CACHE_FILE="/tmp/ai-framework-update-${SHORT_HASH}"
  CACHE_MAX_AGE=300

  cache_stale=1
  if [ -f "$CACHE_FILE" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    [ "$age" -lt "$CACHE_MAX_AGE" ] && cache_stale=0
  fi

  if [ "$cache_stale" -eq 1 ]; then
    latest=$(gh api "repos/${REPO}/commits/HEAD" --jq '{sha:.sha,date:.commit.committer.date}' 2>/dev/null)
    echo "$latest" > "$CACHE_FILE"
  else
    latest=$(cat "$CACHE_FILE")
  fi

  if [ -n "$latest" ]; then
    LATEST_HASH=$(echo "$latest" | jq -r '.sha // empty' 2>/dev/null)
    LATEST_DATE=$(echo "$latest" | jq -r '.date // empty' 2>/dev/null | cut -c1-10)
    if [ -n "$LATEST_HASH" ] && [ "$LOCAL_HASH" != "$LATEST_HASH" ]; then
      LATEST_SHORT="${LATEST_HASH:0:7}"
      update_info=" | update: ${LATEST_SHORT} (${LATEST_DATE}) — say \"update the framework\""
    fi
  fi
fi

echo "AI Framework ${SHORT_HASH} · ${INSTALLED_AT}${update_info}"
