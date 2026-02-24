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
echo "This ID should be used to identify this session in all wrap-up summaries and logs."

# Inject project memory if it exists
MEMORY_FILE="${CLAUDE_PROJECT_DIR}/.claude/project/memory.md"
if [ -f "$MEMORY_FILE" ]; then
  echo ""
  echo "--- Project Memory ---"
  cat "$MEMORY_FILE"
  echo "--- End Project Memory ---"
fi

exit 0
