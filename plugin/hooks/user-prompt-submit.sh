#!/bin/bash
# UserPromptSubmit hook:
# - Injects a compaction reminder as the context grows (session-watch), as
#   JSON with a one-line systemMessage for the user.
# - Injects the active model and effort level when they change (calibrate).
# Stdout is either one JSON object (when session-watch fires, carrying the
# calibrate line too) or plain calibrate text, never both.

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9_-')
STATE=""
[ -n "$SESSION_ID" ] && STATE="${TMPDIR:-/tmp}/mallet-calibrate-${SESSION_ID}.json"

# --- Session watch: suggest compaction as the context grows ---
# Cost tracks context size, not prompt count or window percentage: every turn
# re-reads the whole context, so a 350k-token session costs the same per turn
# whatever the window size. Context size is the last real assistant record's
# input + cache-creation + cache-read tokens. Warn at THRESHOLD and again at
# each further STEP; dropping below THRESHOLD (after /compact) re-arms it.
# Only the transcript's tail is read, since transcripts reach several MB; lines
# that fail to parse (one may be mid-write) and all-zero usage are skipped.
THRESHOLD=${CLAUDE_CTX_WARN_THRESHOLD:-150000}
STEP=${CLAUDE_CTX_WARN_STEP:-50000}
case "$THRESHOLD" in ''|*[!0-9]*) THRESHOLD=150000 ;; esac
case "$STEP" in ''|*[!0-9]*) STEP=50000 ;; esac
THRESHOLD=$((10#$THRESHOLD)); STEP=$((10#$STEP))   # 08 would otherwise be read as octal
[ "$STEP" -gt 0 ] || STEP=50000
WATCH_MSG=""
if [ -n "$SESSION_ID" ] && [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  TOKENS=$(tail -n 200 "$TRANSCRIPT_PATH" | jq -rRs '
    [split("\n")[] | fromjson? | select(type == "object")
     | select(.type == "assistant" and .isSidechain != true
              and (.message.usage | type) == "object"
              and .message.model != "<synthetic>")]
    | map(.message.usage
          | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)
          | select(. > 0))
    | last // empty')
  case "$TOKENS" in ''|*[!0-9]*) TOKENS="" ;; esac
  WATCH="${TMPDIR:-/tmp}/mallet-watch-${SESSION_ID}.last"
  if [ -n "$TOKENS" ] && [ "$TOKENS" -lt "$THRESHOLD" ]; then
    rm -f "$WATCH"
  elif [ -n "$TOKENS" ]; then
    BUCKET=$(( (TOKENS - THRESHOLD) / STEP + 1 ))
    LAST_BUCKET=0
    [ -f "$WATCH" ] && LAST_BUCKET=$(cat "$WATCH")
    case "$LAST_BUCKET" in ''|*[!0-9]*) LAST_BUCKET=0 ;; esac
    if [ "$BUCKET" -gt "$LAST_BUCKET" ]; then
      K=$(( (TOKENS + 500) / 1000 ))
      STEP_K=$(( STEP / 1000 ))
      WATCH_USER="Context is about ${K}k tokens. Compacting or checkpointing is worth it."
      WATCH_MSG="[session-watch] Context is about ${K}k tokens, and every turn re-reads all of it, so each further turn costs at least that much. Say once, this turn, that a /checkpoint then /compact is worth it and why. Do not repeat it until the next ${STEP_K}k step."
      echo "$BUCKET" > "$WATCH"
    fi
  fi
fi

# --- Calibrate: active model and effort ---
# Whether a prompt warrants a different model or effort is judged by the model
# itself (see the Task Calibration directive). Hook input carries neither value,
# so this supplies them: from the state file statusline.sh writes on every
# render (live, including mid-session /effort and /model changes), else from
# settings. Emitted only when the values change, so it costs nothing per turn.

CALIBRATE=""
if [ -n "$SESSION_ID" ]; then
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
      CALIBRATE="$LINE"
      echo "$LINE" > "$LAST" 2>/dev/null
    fi
  fi
fi

if [ -n "$WATCH_MSG" ]; then
  CONTEXT="$WATCH_MSG"
  [ -n "$CALIBRATE" ] && CONTEXT="${CONTEXT}
${CALIBRATE}"
  jq -nc --arg user "$WATCH_USER" --arg ctx "$CONTEXT" \
    '{systemMessage: $user, hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
elif [ -n "$CALIBRATE" ]; then
  echo "$CALIBRATE"
fi

exit 0
