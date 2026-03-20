#!/bin/bash
# Generates a 3-word session ID in the style of Netlify deploy names,
# persists it as an environment variable, and injects it into Claude's context.

ADJECTIVES=(
  brave calm clever cool crisp deft eager fair fast fine
  glad keen kind lean light mild neat pure quick safe
  sharp sleek slim smooth soft swift tall warm wise bold
  bright clear fresh gentle hardy noble proud quiet steady true
)

NOUNS=(
  atlas bear cedar cliff crane dawn deer dune eagle fern
  finch flame flint forge frost grove hawk heath heron jade
  kestrel lake lark linden lynx maple marsh mist orchid osprey
  otter peak pine prism raven ridge robin sage slate sparrow
  spruce stone storm swift thorn tide vale wren amber aspen
)

VERBS=(
  blooms drifts flies glows grows leaps moves runs shines soars
  sparks stands streams turns walks wades builds carves finds forms
  holds keeps learns lifts pulls reads rides sails seeks shapes
  shows skims spans stars swims turns vaults weaves winds yields
)

# Pick one word from each list using random index
A=${ADJECTIVES[$RANDOM % ${#ADJECTIVES[@]}]}
N=${NOUNS[$RANDOM % ${#NOUNS[@]}]}
V=${VERBS[$RANDOM % ${#VERBS[@]}]}

TS=$(printf '%04d' $(( $(date +%s) % 10000 )))
SESSION_ID="${A}-${N}-${V}-${TS}"

# Persist as environment variable for this session and all subsequent Bash calls
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "SESSION_ID=${SESSION_ID}" >> "$CLAUDE_ENV_FILE"
fi

# Write to a file so the wrap-up skill and other hooks can reference it
SESSION_FILE="${CLAUDE_PROJECT_DIR}/.claude/sessions/.current"
mkdir -p "$(dirname "$SESSION_FILE")"
echo "$SESSION_ID" > "$SESSION_FILE"

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
