#!/bin/bash
# PreCompact hook: captures in-progress state before conversation compaction.
#
# Two outputs:
#   1. stdout  — injected into the compaction context so critical state
#                survives the summarisation pass in the current session.
#   2. snapshot file — read by session-start.sh when a NEW session begins
#                after a compaction, restoring continuity across restarts.

SNAPSHOT_FILE="${CLAUDE_PROJECT_DIR}/.mallet/compact-snapshot.md"

# .mallet/ may not exist yet in a project that has never stored Mallet state.
# If it cannot be created, still emit the snapshot to stdout (output 1 of 2) and
# drop only the file write — a PreCompact hook must never block compaction.
mkdir -p "$(dirname "$SNAPSHOT_FILE")" 2>/dev/null || SNAPSHOT_FILE=/dev/null

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

  MISSION_FILE="${CLAUDE_PROJECT_DIR}/.mallet/missions/active.md"
  if [ -f "$MISSION_FILE" ]; then
    echo ""
    echo "Active mission:"
    cat "$MISSION_FILE"
  fi

  echo "</pre-compact-snapshot>"
} | tee "$SNAPSHOT_FILE"

exit 0
