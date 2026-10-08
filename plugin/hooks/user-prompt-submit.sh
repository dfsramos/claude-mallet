#!/bin/bash
# UserPromptSubmit hook:
# - Injects a compaction reminder as the context window fills (prompt count
#   when no statusline data is available).
# - Injects the active model and effort level when they change (calibrate).

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9_-')
STATE=""
[ -n "$SESSION_ID" ] && STATE="${TMPDIR:-/tmp}/mallet-calibrate-${SESSION_ID}.json"

# --- Session watch: suggest compaction as the context window fills ---
# Context usage comes from the state file statusline.sh writes on every render.
# Warn at 60% and again at each further 15%; a drop below 60% (after /compact)
# re-arms the first warning.
CTX=""
[ -n "$STATE" ] && [ -f "$STATE" ] && CTX=$(jq -r '.ctx // empty' "$STATE" 2>/dev/null)
if [ -n "$CTX" ]; then
  PCT="${CTX%%.*}"   # truncate; printf '%.0f' fails under comma-decimal locales
  case "$PCT" in ''|*[!0-9]*) PCT=0 ;; esac
  WATCH="${TMPDIR:-/tmp}/mallet-watch-${SESSION_ID}.last"
  if [ "${PCT:-0}" -lt 60 ]; then
    echo 0 > "$WATCH" 2>/dev/null
  else
    BUCKET=$(( (PCT - 60) / 15 + 1 ))
    LAST_BUCKET=$(cat "$WATCH" 2>/dev/null); LAST_BUCKET=${LAST_BUCKET:-0}
    if [ "$BUCKET" -gt "$LAST_BUCKET" ]; then
      if [ "$BUCKET" -eq 1 ]; then
        echo "[session-watch] Context ${PCT}% full — consider /compact (or /checkpoint first) before continuing. Every turn re-reads the whole context."
      else
        echo "[session-watch] Context ${PCT}% full — high-cost zone. Run /compact now; recall also degrades as the window fills."
      fi
      echo "$BUCKET" > "$WATCH" 2>/dev/null
    fi
  fi
else
  # No statusline data: fall back to counting human-typed prompts.
  # Tool results, agent hand-backs and skill expansions are also stored as
  # role "user"; counting them inflated the total roughly 7x. Current
  # transcripts mark typed prompts with origin.kind == "human"; older ones have
  # no origin, so fall back to excluding meta entries and tool results.
  # Twin of the predicate in statusline.sh — keep in sync. Streamed with
  # reduce inputs rather than slurped, since this runs on every prompt.
  HUMAN_DEF='def human: (.isSidechain != true and .isApiErrorMessage != true and ((.message.role // .role) == "user"))
    and (if .origin then .origin.kind == "human"
         else (.isMeta != true and ((.message.content | type) == "string"
               or ((.message.content | type) == "array" and (any(.message.content[]; .type == "tool_result") | not))))
         end);'
  TURN_COUNT=0
  if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    PREV=$(jq -rn "$HUMAN_DEF"' reduce inputs as $e (0; if ($e | human) then . + 1 else . end)' "$TRANSCRIPT_PATH" 2>/dev/null)
    TURN_COUNT=$(( ${PREV:-0} + 1 ))
  fi
  if [ "$TURN_COUNT" -eq 50 ]; then
    echo "[session-watch] 50 prompts — consider running /compact before continuing. Long sessions are the primary driver of token costs."
  elif [ "$TURN_COUNT" -ge 80 ] && [ $(( (TURN_COUNT - 80) % 20 )) -eq 0 ]; then
    echo "[session-watch] ${TURN_COUNT} prompts — high-cost zone. Run /compact now to reduce output tokens for the remainder of this session."
  fi
fi

# --- Calibrate: active model and effort ---
# Whether a prompt warrants a different model or effort is judged by the model
# itself (see the Task Calibration directive). Hook input carries neither value,
# so this supplies them: from the state file statusline.sh writes on every
# render (live, including mid-session /effort and /model changes), else from
# settings. Emitted only when the values change, so it costs nothing per turn.

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
      echo "$LINE"
      echo "$LINE" > "$LAST" 2>/dev/null
    fi
  fi
fi

exit 0
