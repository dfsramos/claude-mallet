#!/bin/bash
# SessionStart hook (matcher: compact): restores working state right after a
# compaction, in the same session. SessionStart stdout is added to the model's
# context; PreCompact stdout is not, which is why this replaced pre-compact.sh.
#
# Emits fresh state rather than a snapshot taken before compaction, so there is
# no file to persist and nothing to leak into a later, unrelated session.

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

# Hook output over 10,000 characters reaches Claude only as a file path and a
# preview, so the mission is capped well below that alongside the git output.
# The cap counts bytes, which is stricter than the character limit.
MISSION_CAP=7000
MISSIONS="${DIR}/.mallet/missions"
if ls "$MISSIONS"/*.md >/dev/null 2>&1; then
  echo ""
  echo "Mission files: $(cd "$MISSIONS" && ls *.md | head -20 | tr '\n' ' ')"
  if [ -f "$MISSIONS/active.md" ]; then
    echo ""
    echo "Active mission:"
    head -c "$MISSION_CAP" "$MISSIONS/active.md"
    if [ "$(wc -c < "$MISSIONS/active.md")" -gt "$MISSION_CAP" ]; then
      echo ""
      echo "[truncated at $MISSION_CAP bytes — read .mallet/missions/active.md for the rest]"
    fi
  fi
fi

echo "</post-compact-state>"
exit 0
