#!/bin/bash
# PreCompact hook: captures in-progress state before conversation compaction.
#
# Two outputs:
#   1. stdout  — injected into the compaction context so critical state
#                survives the summarisation pass in the current session.
#   2. snapshot file — read by session-start.sh when a NEW session begins
#                after a compaction, restoring continuity across restarts.

SNAPSHOT_FILE="${CLAUDE_PROJECT_DIR}/.claude/project/compact-snapshot.md"

{
  echo "<pre-compact-snapshot>"
  echo "Captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # ── Git state ──────────────────────────────────────────────────────────────

  if git -C "$CLAUDE_PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    BRANCH=$(git -C "$CLAUDE_PROJECT_DIR" branch --show-current 2>/dev/null)
    echo "Branch: ${BRANCH}"

    STATUS=$(git -C "$CLAUDE_PROJECT_DIR" status --short 2>/dev/null | head -15)
    if [ -n "$STATUS" ]; then
      echo ""
      echo "Uncommitted changes:"
      echo "$STATUS"
    fi

    echo ""
    echo "Recent commits:"
    git -C "$CLAUDE_PROJECT_DIR" log --oneline -5 2>/dev/null
  fi

  # ── Active mission ─────────────────────────────────────────────────────────

  MISSION_FILE="${CLAUDE_PROJECT_DIR}/.claude/project/missions/active.md"
  if [ -f "$MISSION_FILE" ]; then
    echo ""
    echo "Active mission:"
    cat "$MISSION_FILE"
  fi

  echo "</pre-compact-snapshot>"
} | tee "$SNAPSHOT_FILE"

exit 0
