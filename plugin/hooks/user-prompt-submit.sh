#!/bin/bash
# UserPromptSubmit hook:
# - Injects a compaction reminder when the session exceeds prompt thresholds.
# - Injects the active model and effort level when they change (calibrate).

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

# --- Turn counter (derived from transcript) ---
# Human-typed prompts only. Tool results, agent hand-backs and skill expansions
# are also stored as role "user"; counting them inflated the total roughly 7x.
# Current transcripts mark typed prompts with origin.kind == "human"; older ones
# have no origin, so fall back to excluding meta entries and tool results.
# Twin of the filter in statusline.sh / user-prompt-submit.sh — keep in sync.
HUMAN_PROMPTS='[.[] | select(.isSidechain != true and .isApiErrorMessage != true and ((.message.role // .role) == "user"))
  | select(if .origin then .origin.kind == "human"
           else (.isMeta != true and ((.message.content | type) == "string"
                 or ((.message.content | type) == "array" and (any(.message.content[]; .type == "tool_result") | not))))
           end)] | length'
TURN_COUNT=0
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  PREV=$(jq -rs "$HUMAN_PROMPTS" "$TRANSCRIPT_PATH" 2>/dev/null)
  TURN_COUNT=$(( ${PREV:-0} + 1 ))
fi

# Warn at thresholds
if [ "$TURN_COUNT" -eq 50 ]; then
  echo "[session-watch] 50 prompts — consider running /compact before continuing. Long sessions are the primary driver of token costs."
elif [ "$TURN_COUNT" -ge 80 ] && [ $(( (TURN_COUNT - 80) % 20 )) -eq 0 ]; then
  echo "[session-watch] ${TURN_COUNT} prompts — high-cost zone. Run /compact now to reduce output tokens for the remainder of this session."
fi

# --- Calibrate: active model and effort ---
# Whether a prompt warrants a different model or effort is judged by the model
# itself (see the Task Calibration directive). Hook input carries neither value,
# so this supplies them: from the state file statusline.sh writes on every
# render (live, including mid-session /effort and /model changes), else from
# settings. Emitted only when the values change, so it costs nothing per turn.

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9_-')
if [ -n "$SESSION_ID" ]; then
  STATE="${TMPDIR:-/tmp}/mallet-calibrate-${SESSION_ID}.json"
  LAST="${TMPDIR:-/tmp}/mallet-calibrate-${SESSION_ID}.last"

  MODEL=""; EFFORT=""; SOURCE=""
  if [ -f "$STATE" ]; then
    MODEL=$(jq -r '.model // empty' "$STATE" 2>/dev/null)
    EFFORT=$(jq -r '.effort // empty' "$STATE" 2>/dev/null)
  fi
  if [ ! -f "$STATE" ]; then
    # No Mallet statusline in use. A state file with no effort means the model
    # has no effort parameter, so settings must not be consulted in that case.
    # Most specific settings file wins, matching Claude Code's precedence.
    for f in "${CLAUDE_PROJECT_DIR}/.claude/settings.local.json" \
             "${CLAUDE_PROJECT_DIR}/.claude/settings.json" \
             "${HOME}/.claude/settings.json"; do
      [ -f "$f" ] || continue
      EFFORT=$(jq -r '.effortLevel // empty' "$f" 2>/dev/null)
      if [ -n "$EFFORT" ]; then SOURCE=" (from settings; /effort changes not visible)"; break; fi
    done
  fi

  if [ -n "$MODEL" ] || [ -n "$EFFORT" ]; then
    # The model knows its own name; state it only when the statusline supplied it.
    if [ -n "$MODEL" ]; then
      LINE="[calibrate] active model: ${MODEL}; effort: ${EFFORT:-unknown}${SOURCE}"
    else
      LINE="[calibrate] active effort: ${EFFORT}${SOURCE}"
    fi
    if [ "$LINE" != "$(cat "$LAST" 2>/dev/null)" ]; then
      echo "$LINE"
      echo "$LINE" > "$LAST" 2>/dev/null
    fi
  fi
fi

exit 0
