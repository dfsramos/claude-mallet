#!/bin/bash
# UserPromptSubmit hook: scores prompt complexity and tracks session turn count.
# - Injects a task-calibrate reminder when high-complexity signals are detected.
# - Injects a compaction reminder when the session exceeds turn thresholds.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

# --- Turn counter ---
if [ -n "$SESSION_ID" ]; then
  TURN_FILE="/tmp/ai-framework-turns-${SESSION_ID}"
  TURN_COUNT=1
  if [ -f "$TURN_FILE" ]; then
    TURN_COUNT=$(( $(cat "$TURN_FILE") + 1 ))
  fi
  echo "$TURN_COUNT" > "$TURN_FILE"

  # Write session pointer for statusline
  if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    echo "$SESSION_ID" > "${CLAUDE_PROJECT_DIR}/.claude/sessions/.current-id"
  fi

  # Warn at thresholds
  if [ "$TURN_COUNT" -eq 50 ]; then
    echo "[session-watch] 50 prompts — consider running /compact before continuing. Long sessions are the primary driver of token costs."
  elif [ "$TURN_COUNT" -ge 80 ] && [ $(( (TURN_COUNT - 80) % 20 )) -eq 0 ]; then
    echo "[session-watch] ${TURN_COUNT} prompts — high-cost zone. Run /compact now to reduce output tokens for the remainder of this session."
  fi
fi

if [ -z "$PROMPT" ]; then
  exit 0
fi

# --- Scoring ---

SCORE=0

# Architectural / design signals (+2 each)
ARCH_PATTERN="(architect|redesign|rethink|overhaul|refactor|strategy|tradeoff|trade-off|migrate|migration|from scratch|evaluate|pros and cons|which approach|compare.*approach|approach.*compare)"
if echo "$PROMPT" | grep -qiE "$ARCH_PATTERN"; then
  SCORE=$((SCORE + 2))
fi

# Planning / multi-system signals (+2)
PLAN_PATTERN="(should (i|we)|plan (the|a|this)|design (the|a|this)|how (should|do) (i|we) (structure|organise|organize|build|implement)|cross.cutting|the whole|system.wide)"
if echo "$PROMPT" | grep -qiE "$PLAN_PATTERN"; then
  SCORE=$((SCORE + 2))
fi

# Long prompt (+1 if > 80 words)
WORD_COUNT=$(echo "$PROMPT" | wc -w)
if [ "$WORD_COUNT" -gt 80 ]; then
  SCORE=$((SCORE + 1))
fi

# --- Output ---

if [ "$SCORE" -ge 3 ]; then
  echo "[task-calibrate] High-complexity task detected (score=${SCORE}). Invoke the task-calibrate skill to assess whether Opus would serve this task better before proceeding."
fi

exit 0
