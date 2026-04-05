#!/bin/bash
# UserPromptSubmit hook: scores prompt complexity and flags high-complexity tasks.
# Injects a system-reminder instructing Claude to invoke task-calibrate when warranted.

PROMPT=$(jq -r '.prompt // empty' 2>/dev/null)

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
