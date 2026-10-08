#!/bin/bash
# Statusline: shows model and effort, git branch, and usage.
# Receives Claude Code session JSON via stdin.

input=$(cat)

# Resolve the project dir for git/branch reporting (env var preferred, JSON fallback).
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(echo "$input" | jq -r '.workspace.project_dir // empty' 2>/dev/null)}"

# jq is required by every segment below.
command -v jq &>/dev/null || exit 0

# Calibrate: record the live model and effort for user-prompt-submit.sh, which
# cannot see either in its own hook input.
# effort.level tracks mid-session /effort changes; it is absent when the model
# has no effort parameter.
cal_sid=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9_-')
if [ -n "$cal_sid" ]; then
  echo "$input" | jq -c '{model: (.model.id // null), effort: (.effort.level // null)}' \
    > "${TMPDIR:-/tmp}/mallet-calibrate-${cal_sid}.json" 2>/dev/null
fi

model_name=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null)
effort_level=$(echo "$input" | jq -r '.effort.level // empty' 2>/dev/null)

# Helpers ────────────────────────────────────────────────────────────────────

# Format seconds as "Xd Yh", "Xh Ym", or "Xm"
format_remaining() {
  local secs=$1
  local days=$(( secs / 86400 ))
  local hours=$(( (secs % 86400) / 3600 ))
  local mins=$(( (secs % 3600) / 60 ))
  if   [ $days -gt 0 ];  then echo "${days}d ${hours}h"
  elif [ $hours -gt 0 ]; then echo "${hours}h ${mins}m"
  else                        echo "${mins}m"
  fi
}

# Format a token count as "N", "Nk", or "N.NNM"
format_tokens() {
  local n=$1
  if   [ "$n" -ge 1000000 ]; then LC_ALL=C awk "BEGIN{printf \"%.2fM\", $n/1000000}"
  elif [ "$n" -ge 1000 ];    then echo "$(( (n + 500) / 1000 ))k"
  else                            echo "$n"
  fi
}

# Join the arguments with " · " and echo the line. Takes the elements, not an
# array name: a nameref (`local -n`) needs bash 4.3, and macOS ships 3.2.
emit_line() {
  [ $# -eq 0 ] && return
  local out="$1"
  shift
  local p
  for p in "$@"; do out+=" · $p"; done
  echo "$out"
}

now=$(date +%s)

# Line 1: model · effort · branch ─────────────────────────────────────────────
line1_parts=()
[ -n "$model_name" ] && line1_parts+=("$model_name")
[ -n "$effort_level" ] && line1_parts+=("effort: $effort_level")
if [ -n "$PROJECT_DIR" ] && command -v git &>/dev/null; then
  branch=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
  repo_name=$(basename "$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null)")
  [ -n "$branch" ] && line1_parts+=("⎇ ${repo_name}/${branch}")
fi
emit_line "${line1_parts[@]}"

# Line 2: cost · context · 7d · 5h ───────────────────────────────────────────
line2_parts=()

cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
[ -n "$cost" ] && line2_parts+=("\$$(LC_ALL=C printf '%.4f' "$cost")")

# Context size in tokens: what every turn re-reads, so what each turn costs.
# total_input_tokens is input + cache writes + cache reads from the latest
# response, the same figure session-watch reads from the transcript. 0 before
# the first response.
ctx_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty' 2>/dev/null)
case "$ctx_tokens" in ''|*[!0-9]*) ctx_tokens=0 ;; esac
session_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
if [ "$ctx_tokens" -gt 0 ]; then
  s="ctx $(format_tokens "$ctx_tokens")"
  [ -n "$session_pct" ] && s+=" ($(LC_ALL=C printf '%.0f' "$session_pct")%)"
  line2_parts+=("$s")
elif [ -n "$session_pct" ]; then
  line2_parts+=("ctx $(LC_ALL=C printf '%.0f' "$session_pct")%")
fi

seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
if [ -n "$seven_day" ]; then
  s="7d: $(LC_ALL=C printf '%.0f' "$seven_day")%"
  resets_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)
  [ -n "$resets_at" ] && [ "$resets_at" -gt "$now" ] && s+=" ($(format_remaining $(( resets_at - now ))))"
  line2_parts+=("$s")
fi

five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
if [ -n "$five_hour" ]; then
  s="5h: $(LC_ALL=C printf '%.0f' "$five_hour")%"
  resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
  [ -n "$resets_at" ] && [ "$resets_at" -gt "$now" ] && s+=" ($(format_remaining $(( resets_at - now ))))"
  line2_parts+=("$s")
fi

emit_line "${line2_parts[@]}"
