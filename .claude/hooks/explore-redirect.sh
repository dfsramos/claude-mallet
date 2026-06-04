#!/bin/bash
# PreToolUse hook: steers broad codebase searches toward richer sources.
#
# When Claude runs a broad grep/find/ripgrep against the whole codebase,
# this hook checks whether a smarter starting point is available and
# injects a suggestion. Always advisory (exit 0) — never blocks.
#
# Triggers on:
#   - grep -r / grep -rn / grep -rl (recursive grep)
#   - find . (broad find from project root)
#   - rg / ag / ripgrep invocations
#
# Suggests:
#   1. Graphify knowledge graph  — if graphify-out/graph.json exists
#   2. Discovery report          — if .claude/project/discovery-*.md exists

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

if [ "$TOOL" != "Bash" ]; then
  exit 0
fi

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only proceed on commands that look like broad codebase searches
if ! echo "$CMD" | grep -qE 'grep -r|grep -rn|grep -rl|find \.|rg |ag |ripgrep'; then
  exit 0
fi

SUGGESTIONS=0

# ── Graphify knowledge graph ─────────────────────────────────────────────────

GRAPH="${CLAUDE_PROJECT_DIR}/graphify-out/graph.json"
if [ -f "$GRAPH" ]; then
  echo "[explore-redirect] A Graphify knowledge graph exists (graphify-out/graph.json). Consider querying it instead:"
  echo "  /graphify query \"<question>\"    — semantic search across the whole codebase"
  echo "  /graphify path \"<A>\" \"<B>\"      — shortest connection between two concepts"
  echo "  /graphify explain \"<symbol>\"    — explain a specific entity"
  SUGGESTIONS=$((SUGGESTIONS + 1))
fi

# ── Discovery report (critical files list) ───────────────────────────────────

REPORT=$(ls "${CLAUDE_PROJECT_DIR}/.claude/project/discovery-"*.md 2>/dev/null | sort | tail -1)
if [ -n "$REPORT" ]; then
  REPORT_NAME=$(basename "$REPORT")
  echo "[explore-redirect] A discovery report exists (.claude/project/${REPORT_NAME})."
  echo "  Its Critical Files section lists the highest-centrality modules — check those first"
  echo "  to narrow your search before grepping broadly."
  SUGGESTIONS=$((SUGGESTIONS + 1))
fi

exit 0
