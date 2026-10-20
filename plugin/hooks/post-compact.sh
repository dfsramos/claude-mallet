#!/bin/bash
# SessionStart hook (matcher: compact): restores working state right after a
# compaction, in the same session. SessionStart stdout is added to the model's
# context; PreCompact stdout is not, which is why this replaced pre-compact.sh.
#
# Emits fresh state rather than a snapshot taken before compaction, so there is
# no file to persist and nothing to leak into a later, unrelated session. Git
# state only: CLAUDE.md, .claude/rules/ and auto memory are re-read by Claude
# Code itself after compaction, and open work lives in auto memory.

DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

echo "<post-compact-state>"

if git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Branch: $(git -C "$DIR" branch --show-current)"

  STATUS=$(git -C "$DIR" status --short | head -15)
  if [ -n "$STATUS" ]; then
    echo ""
    echo "Uncommitted changes:"
    echo "$STATUS"
  fi

  echo ""
  echo "Recent commits:"
  git -C "$DIR" log --oneline -5
fi

echo "</post-compact-state>"
exit 0
