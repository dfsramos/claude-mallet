#!/bin/bash
# Statusline: shows AI Framework version, available update, git branch, and usage.
# Receives Claude Code session JSON via stdin.

input=$(cat)

# Locate framework.json from project dir (env var preferred, JSON fallback)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(echo "$input" | jq -r '.workspace.project_dir // empty' 2>/dev/null)}"
FRAMEWORK_JSON="${PROJECT_DIR}/.claude/framework.json"

[ ! -f "$FRAMEWORK_JSON" ] && exit 0
command -v jq &>/dev/null || exit 0

LOCAL_HASH=$(jq -r '.version // empty' "$FRAMEWORK_JSON")
INSTALLED_AT=$(jq -r '.installed_at // empty' "$FRAMEWORK_JSON")
REPO=$(jq -r '.repo // empty' "$FRAMEWORK_JSON")

[ -z "$LOCAL_HASH" ] && exit 0

SHORT_HASH="${LOCAL_HASH:0:7}"
update_info=""

# Check for updates — cached per installed version (5 min TTL)
if command -v gh &>/dev/null && [ -n "$REPO" ]; then
  CACHE_FILE="/tmp/ai-framework-update-${SHORT_HASH}"
  CACHE_MAX_AGE=300

  cache_stale=1
  if [ -f "$CACHE_FILE" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    [ "$age" -lt "$CACHE_MAX_AGE" ] && cache_stale=0
  fi

  if [ "$cache_stale" -eq 1 ]; then
    latest=$(gh api "repos/${REPO}/commits/HEAD" --jq '{sha:.sha,date:.commit.committer.date}' 2>/dev/null)
    echo "$latest" > "$CACHE_FILE"
  else
    latest=$(cat "$CACHE_FILE")
  fi

  if [ -n "$latest" ]; then
    LATEST_HASH=$(echo "$latest" | jq -r '.sha // empty' 2>/dev/null)
    LATEST_DATE=$(echo "$latest" | jq -r '.date // empty' 2>/dev/null | cut -c1-10)
    if [ -n "$LATEST_HASH" ] && [ "$LOCAL_HASH" != "$LATEST_HASH" ]; then
      LATEST_SHORT="${LATEST_HASH:0:7}"
      update_info=" | update: ${LATEST_SHORT} (${LATEST_DATE}) — say \"update the framework\""
    fi
  fi
fi

echo "AI Framework ${SHORT_HASH} · ${INSTALLED_AT}${update_info}"

# ── Second line: git branch + usage ─────────────────────────────────────────

# Helper: format seconds as "Xd Yh", "Xh Ym", or "Xm"
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

parts=()
now=$(date +%s)

# Repo/branch (from project dir)
if [ -n "$PROJECT_DIR" ] && command -v git &>/dev/null; then
  branch=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
  repo_name=$(basename "$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null)")
  [ -n "$branch" ] && parts+=("⎇ ${repo_name}/${branch}")
fi

# Session cost
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
[ -n "$cost" ] && parts+=("\$$(printf '%.4f' "$cost")")

# Session usage — context window percentage
session_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
[ -n "$session_pct" ] && parts+=("◷ $(printf '%.0f' "$session_pct")%")

# 7-day rate limit + time to reset
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
if [ -n "$seven_day" ]; then
  seven_day_str="7d: $(printf '%.0f' "$seven_day")%"
  resets_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)
  if [ -n "$resets_at" ] && [ "$resets_at" -gt "$now" ]; then
    seven_day_str+=" ($(format_remaining $(( resets_at - now ))))"
  fi
  parts+=("$seven_day_str")
fi

# 5-hour rate limit + time to reset
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
if [ -n "$five_hour" ]; then
  five_hour_str="5h: $(printf '%.0f' "$five_hour")%"
  resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
  if [ -n "$resets_at" ] && [ "$resets_at" -gt "$now" ]; then
    five_hour_str+=" ($(format_remaining $(( resets_at - now ))))"
  fi
  parts+=("$five_hour_str")
fi

# Session turn count from transcript
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  TURNS=$(jq -rs '[.[] | select(.isSidechain != true and .isApiErrorMessage != true and ((.message.role // .role) == "user"))] | length' "$transcript_path" 2>/dev/null)
  [ -n "$TURNS" ] && [ "$TURNS" -gt 0 ] && parts+=("T:${TURNS}")
fi

if [ ${#parts[@]} -gt 0 ]; then
  result="${parts[0]}"
  for part in "${parts[@]:1}"; do
    result+=" · $part"
  done
  echo "$result"
fi
