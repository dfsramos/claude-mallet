#!/bin/bash
# Session startup hook:
#   1. Injects project memory into context (if present).
#   2. Checks for a framework update and surfaces it as a notice (if available).

# ── Project memory ──────────────────────────────────────────────────────────

MEMORY_FILE="${CLAUDE_PROJECT_DIR}/.mallet/memory.md"
if [ -f "$MEMORY_FILE" ]; then
  echo "--- Project Memory ---"
  cat "$MEMORY_FILE"
  echo "--- End Project Memory ---"
fi

# ── Post-compaction snapshot ────────────────────────────────────────────────
# If a compact snapshot was written before the last compaction, inject it so
# Claude can restore continuity without re-reading the full conversation.

SNAPSHOT_FILE="${CLAUDE_PROJECT_DIR}/.mallet/compact-snapshot.md"
if [ -f "$SNAPSHOT_FILE" ]; then
  echo "--- Compact Snapshot (from last compaction) ---"
  cat "$SNAPSHOT_FILE"
  echo "--- End Compact Snapshot ---"
  rm -f "$SNAPSHOT_FILE"
fi

# ── Framework update check ──────────────────────────────────────────────────

FRAMEWORK_JSON="${HOME}/.claude/framework.json"
CACHE_FILE="${HOME}/.claude/.mallet-update-check"
CACHE_TTL=86400

if [ -f "$FRAMEWORK_JSON" ] && command -v jq >/dev/null; then
  LOCAL_HASH=$(jq -r '.version // empty' "$FRAMEWORK_JSON" 2>/dev/null)
  REPO=$(jq -r '.repo // empty' "$FRAMEWORK_JSON" 2>/dev/null)

  if [ -n "$LOCAL_HASH" ] && [ -n "$REPO" ]; then
    LATEST_HASH=""
    LATEST_DATE=""

    # Reuse a fresh cached result. Mallet is installed once at ~/.claude/, so
    # this hook now runs in every session in every directory — querying the
    # GitHub API each time would exhaust the 60 req/hr unauthenticated limit
    # and silently disable update notices for the rest of the hour.
    if [ -f "$CACHE_FILE" ]; then
      read -r CACHED_AT CACHED_HASH CACHED_DATE < "$CACHE_FILE" 2>/dev/null
      case "$CACHED_AT" in ''|*[!0-9]*) CACHED_AT=0 ;; esac
      if [ $(( $(date +%s) - CACHED_AT )) -lt "$CACHE_TTL" ]; then
        LATEST_HASH="$CACHED_HASH"
        LATEST_DATE="$CACHED_DATE"
      fi
    fi

    # Cache miss or stale entry: query the API. A failed query is never cached,
    # so a transient outage is not recorded as "up to date" for 24 hours.
    if [ -z "$LATEST_HASH" ] && command -v curl >/dev/null; then
      BRANCH=$(curl -sf --max-time 3 "https://api.github.com/repos/${REPO}" | jq -r '.default_branch // empty')

      if [ -n "$BRANCH" ]; then
        LATEST=$(curl -sf --max-time 3 "https://api.github.com/repos/${REPO}/commits/${BRANCH}")
        LATEST_HASH=$(echo "$LATEST" | jq -r '.sha // empty')
        LATEST_DATE=$(echo "$LATEST" | jq -r '.commit.committer.date // empty' | cut -c1-10)

        # Cache the up-to-date case too, or every session re-checks.
        if [ -n "$LATEST_HASH" ]; then
          echo "$(date +%s) ${LATEST_HASH} ${LATEST_DATE}" > "$CACHE_FILE" 2>/dev/null
        fi
      fi
    fi

    if [ -n "$LATEST_HASH" ] && [ "$LOCAL_HASH" != "$LATEST_HASH" ]; then
      echo "--- Framework Update Available ---"
      echo "Current: ${LOCAL_HASH:0:7}"
      echo "Latest:  ${LATEST_HASH:0:7} (${LATEST_DATE})"
      echo "Mention this to the user and offer to run the update skill."
      echo "--- End Framework Update Available ---"
    fi
  fi
fi

# ── Legacy per-project install detection ────────────────────────────────────
# Mallet installs once at ~/.claude/. A framework payload inside the project
# means a pre-migration per-project install is still sitting there. The
# installer's scan catches most of these; this catches the ones it could not
# reach — a repo cloned later, or a scan the user declined.
#
# Deliberately cheap: three -f tests, no traversal and no network. This runs in
# every session in every directory.

# Two exemptions, both of which otherwise nag forever:
#   1. The install itself — a session rooted at $HOME would see ~/.claude/ as a
#      per-project payload.
#   2. The framework source repo — its .claude/ IS the payload. Identified by
#      settings.fragment.json / install-payload.sh, which only the source has.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] \
   && [ "$(cd "${CLAUDE_PROJECT_DIR}" 2>/dev/null && pwd -P)" != "$(cd "${HOME}" 2>/dev/null && pwd -P)" ] \
   && [ ! -f "${CLAUDE_PROJECT_DIR}/.claude/settings.fragment.json" ] \
   && [ ! -f "${CLAUDE_PROJECT_DIR}/.claude/install-payload.sh" ] \
   && [ ! -f "${CLAUDE_PROJECT_DIR}/.mallet/.migration-declined" ]; then
  if [ -f "${CLAUDE_PROJECT_DIR}/.claude/framework.json" ] \
     || { [ -f "${CLAUDE_PROJECT_DIR}/.claude/skills/update/SKILL.md" ] \
          && [ -f "${CLAUDE_PROJECT_DIR}/.claude/agents/_contract.md" ]; }; then
    echo "--- Legacy Mallet Install Detected ---"
    echo "This project contains a per-project Mallet payload; Mallet is now installed at ~/.claude/."
    echo "Offer to run the migrate skill to clean it up. If the user declines, create"
    echo "${CLAUDE_PROJECT_DIR}/.mallet/.migration-declined so this notice stops."
    echo "--- End Legacy Mallet Install Detected ---"
  fi
fi

exit 0
