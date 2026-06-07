#!/bin/bash
# UserPromptSubmit hook: scores prompt complexity and tracks session turn count.
# - Injects a task-calibrate reminder when high-complexity signals are detected.
# - Injects a compaction reminder when the session exceeds turn thresholds.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

# --- Turn counter (derived from transcript) ---
TURN_COUNT=0
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  PREV=$(jq -rs '[.[] | select(.isSidechain != true and .isApiErrorMessage != true and ((.message.role // .role) == "user"))] | length' "$TRANSCRIPT_PATH" 2>/dev/null)
  TURN_COUNT=$(( ${PREV:-0} + 1 ))
fi

# Warn at thresholds
if [ "$TURN_COUNT" -eq 50 ]; then
  echo "[session-watch] 50 prompts — consider running /compact before continuing. Long sessions are the primary driver of token costs."
elif [ "$TURN_COUNT" -ge 80 ] && [ $(( (TURN_COUNT - 80) % 20 )) -eq 0 ]; then
  echo "[session-watch] ${TURN_COUNT} prompts — high-cost zone. Run /compact now to reduce output tokens for the remainder of this session."
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

# --- Ultracode scoring ---

ULTRA_SCORE=0

# Explicit ultracode intent (+3 — sufficient alone to cross threshold)
if echo "$PROMPT" | grep -qiE "(ultracode|ultra (review|audit|sweep|analysis|mode))"; then
  ULTRA_SCORE=$((ULTRA_SCORE + 3))
fi

# Exhaustiveness/comprehensiveness signals (+2)
if echo "$PROMPT" | grep -qiE "(comprehensive|exhaustive|thorough(ly)?|find all|audit all|review (everything|all)|scan all|migrate all|codebase.wide)"; then
  ULTRA_SCORE=$((ULTRA_SCORE + 2))
fi

# Broad scope signals (+1)
if echo "$PROMPT" | grep -qiE "(across (the |this )?(entire |whole )?codebase|every file|all files|entire codebase|whole codebase)"; then
  ULTRA_SCORE=$((ULTRA_SCORE + 1))
fi

# Fan-out task types (+1)
if echo "$PROMPT" | grep -qiE "(security audit|full audit|code audit|bug sweep|dependency audit|coverage gap|dead code|tech.?debt)"; then
  ULTRA_SCORE=$((ULTRA_SCORE + 1))
fi

# --- Output ---

if [ "$SCORE" -ge 3 ]; then
  echo "[task-calibrate] High-complexity task detected (score=${SCORE}). Invoke the task-calibrate skill now, before responding, to check whether a different model would better fit this task."
fi

if [ "$ULTRA_SCORE" -ge 2 ]; then
  echo "[ultracode] Multi-agent execution warranted (score=${ULTRA_SCORE}). Consult the ultracode tier in task-calibrate. If the prompt already contains an explicit ultracode signal, treat it as opt-in and proceed with the Workflow tool directly."
fi

exit 0
