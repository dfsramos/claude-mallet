#!/bin/bash
# Statusline: shows AI Framework version, git branch, and usage.
# Receives Claude Code session JSON via stdin.
# Update checks are handled by the session-start hook.

input=$(cat)

# Locate framework.json from project dir (env var preferred, JSON fallback)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(echo "$input" | jq -r '.workspace.project_dir // empty' 2>/dev/null)}"
FRAMEWORK_JSON="${PROJECT_DIR}/.claude/framework.json"

[ ! -f "$FRAMEWORK_JSON" ] && exit 0
command -v jq &>/dev/null || exit 0

LOCAL_HASH=$(jq -r '.version // empty' "$FRAMEWORK_JSON")
INSTALLED_AT=$(jq -r '.installed_at // empty' "$FRAMEWORK_JSON")

[ -z "$LOCAL_HASH" ] && exit 0

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
  if   [ "$n" -ge 1000000 ]; then awk "BEGIN{printf \"%.2fM\", $n/1000000}"
  elif [ "$n" -ge 1000 ];    then awk "BEGIN{printf \"%.1fk\", $n/1000}"
  else                            echo "$n"
  fi
}

# Join a parts array with " · " separator and echo the line
emit_line() {
  local -n arr=$1
  [ ${#arr[@]} -eq 0 ] && return
  local out="${arr[0]}"
  local p
  for p in "${arr[@]:1}"; do out+=" · $p"; done
  echo "$out"
}

now=$(date +%s)
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)

# Pre-compute token totals from the transcript (single jq pass) ──────────────
tok_in=0; tok_cw=0; tok_cr=0; tok_out=0
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  read -r tok_in tok_cw tok_cr tok_out < <(jq -rs '
    [.[] | select(.message.usage) | .message.usage] as $u |
    [
      ([$u[].input_tokens // 0]                  | add // 0),
      ([$u[].cache_creation_input_tokens // 0]   | add // 0),
      ([$u[].cache_read_input_tokens // 0]       | add // 0),
      ([$u[].output_tokens // 0]                 | add // 0)
    ] | @tsv
  ' "$transcript_path" 2>/dev/null)
  tok_in=${tok_in:-0}; tok_cw=${tok_cw:-0}; tok_cr=${tok_cr:-0}; tok_out=${tok_out:-0}
fi
tok_total=$(( tok_in + tok_cw + tok_cr + tok_out ))

# Line 1: framework version · installed_at · branch ──────────────────────────
line1_parts=("AI Framework ${LOCAL_HASH:0:7}")
[ -n "$INSTALLED_AT" ] && line1_parts+=("$INSTALLED_AT")
if [ -n "$PROJECT_DIR" ] && command -v git &>/dev/null; then
  branch=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
  repo_name=$(basename "$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null)")
  [ -n "$branch" ] && line1_parts+=("⎇ ${repo_name}/${branch}")
fi
emit_line line1_parts

# Line 2: cost · context % · 7d · 5h · turns ─────────────────────────────────
line2_parts=()

cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
[ -n "$cost" ] && line2_parts+=("\$$(printf '%.4f' "$cost")")

session_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
[ -n "$session_pct" ] && line2_parts+=("◷ $(printf '%.0f' "$session_pct")%")

seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
if [ -n "$seven_day" ]; then
  s="7d: $(printf '%.0f' "$seven_day")%"
  resets_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)
  [ -n "$resets_at" ] && [ "$resets_at" -gt "$now" ] && s+=" ($(format_remaining $(( resets_at - now ))))"
  line2_parts+=("$s")
fi

five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
if [ -n "$five_hour" ]; then
  s="5h: $(printf '%.0f' "$five_hour")%"
  resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
  [ -n "$resets_at" ] && [ "$resets_at" -gt "$now" ] && s+=" ($(format_remaining $(( resets_at - now ))))"
  line2_parts+=("$s")
fi

if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  TURNS=$(jq -rs '[.[] | select(.isSidechain != true and .isApiErrorMessage != true and ((.message.role // .role) == "user"))] | length' "$transcript_path" 2>/dev/null)
  [ -n "$TURNS" ] && [ "$TURNS" -gt 0 ] && line2_parts+=("T:${TURNS}")
fi

emit_line line2_parts

# Line 3: token totals + breakdown ───────────────────────────────────────────
if [ "$tok_total" -gt 0 ]; then
  line3_parts=(
    "Σ $(format_tokens "$tok_total")"
    "in: $(format_tokens "$tok_in")"
    "cache_w: $(format_tokens "$tok_cw")"
    "cache_r: $(format_tokens "$tok_cr")"
    "out: $(format_tokens "$tok_out")"
  )
  emit_line line3_parts
fi
