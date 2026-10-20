#!/bin/bash
# SessionStart hook (matcher: startup|resume|clear|compact):
#   1. Keeps the statusline copy in CLAUDE_PLUGIN_DATA current.
#                                                         (startup, resume)
#   2. Detects a legacy per-project Mallet install and offers the migrate skill.
#                                                                    (startup)
#   On resume nothing else runs: the resumed conversation already holds the
#   notices below from when it started.
#   3. Lists project skills in .mallet/skills/, which Claude Code does not load
#      itself.                                                       (all three)
#   4. Points at an open mission in .mallet/missions/active.md.  (startup, clear;
#      after compact, post-compact.sh restores the mission itself)
#   5. In a git repository with no Git conventions of its own, prints Mallet's
#      default rules (rules/git.md) and asks Claude to offer them.  (all three)
# Updates arrive through the plugin system, so there is no update check here.
#
# Project memory is not injected here: Claude Code's auto memory loads its own
# MEMORY.md index at session start.

INPUT=""; [ -t 0 ] || INPUT=$(cat)
# sed rather than jq, so clear/compact are told apart from startup even where
# jq is missing; source is always a bare lowercase word.
SOURCE=$(printf '%s' "$INPUT" | tr -d '\n' | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p')
SOURCE=${SOURCE:-startup}

# ── Statusline copy ─────────────────────────────────────────────────────────
# A statusLine command cannot reference CLAUDE_PLUGIN_ROOT, which changes with
# every plugin version. /mallet:setup points statusLine at this copy in the
# persistent data directory instead, and refreshing it here on every startup
# and resume carries plugin updates through to it. A resume loads the current
# plugin version too, so skipping it left the old statusline running.

if { [ "$SOURCE" = "startup" ] || [ "$SOURCE" = "resume" ]; } && [ -n "${CLAUDE_PLUGIN_DATA:-}" ] && [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  SRC="${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh"
  DST="${CLAUDE_PLUGIN_DATA}/statusline.sh"
  if [ -f "$SRC" ] && ! cmp -s "$SRC" "$DST"; then
    mkdir -p "$CLAUDE_PLUGIN_DATA" && cp "$SRC" "$DST.tmp" && mv "$DST.tmp" "$DST"
  fi
fi
[ "$SOURCE" = "resume" ] && exit 0

# ── Legacy per-project install detection ────────────────────────────────────
# Mallet now ships as a plugin. A framework payload inside the project
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
if [ "$SOURCE" = "startup" ] && [ -n "${CLAUDE_PROJECT_DIR:-}" ] \
   && [ "$(cd "${CLAUDE_PROJECT_DIR}" 2>/dev/null && pwd -P)" != "$(cd "${HOME}" 2>/dev/null && pwd -P)" ] \
   && [ ! -f "${CLAUDE_PROJECT_DIR}/.claude/settings.fragment.json" ] \
   && [ ! -f "${CLAUDE_PROJECT_DIR}/.claude/install-payload.sh" ] \
   && [ ! -f "${CLAUDE_PROJECT_DIR}/.mallet/.migration-declined" ]; then
  if [ -f "${CLAUDE_PROJECT_DIR}/.claude/framework.json" ] \
     || { [ -f "${CLAUDE_PROJECT_DIR}/.claude/skills/update/SKILL.md" ] \
          && [ -f "${CLAUDE_PROJECT_DIR}/.claude/agents/_contract.md" ]; }; then
    echo "--- Legacy Mallet Install Detected ---"
    echo "This project contains a per-project Mallet payload; Mallet now ships as the mallet plugin."
    echo "Offer to run the migrate skill to clean it up. If the user declines, create"
    echo "${CLAUDE_PROJECT_DIR}/.mallet/.migration-declined so this notice stops."
    echo "--- End Legacy Mallet Install Detected ---"
  fi
fi

# ── Project skills ──────────────────────────────────────────────────────────
# The persona treats .mallet/skills/ as an extra skills directory, but Claude
# Code only discovers .claude/skills/. Listing each skill's trigger description
# here is what lets the model notice when one applies. Capped so a large
# directory cannot push the output past the 10,000-character hook limit.

MALLET_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/.mallet"
if ls "$MALLET_DIR"/skills/*/SKILL.md >/dev/null 2>&1; then
  echo "--- Project Skills (.mallet/skills/) ---"
  echo "Claude Code does not load these itself. When one's trigger applies, read its SKILL.md and follow it."
  n=0
  for f in "$MALLET_DIR"/skills/*/SKILL.md; do
    n=$((n + 1)); [ "$n" -gt 25 ] && break
    name=$(basename "$(dirname "$f")")
    # Single-line descriptions only; CRLF and surrounding quotes are stripped.
    desc=$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -1 | tr -d '\r' | sed 's/^["'"'"']//; s/["'"'"']$//' | cut -c1-300)
    echo "- ${name}: ${desc}"
  done
  echo "--- End Project Skills ---"
fi

# ── Open mission ────────────────────────────────────────────────────────────
# Backs the persona's Continuity directive with a signal instead of relying on
# the model to look for the file unprompted.

ACTIVE="$MALLET_DIR/missions/active.md"
pending=0
[ -f "$ACTIVE" ] && pending=$(grep -c '^[[:space:]]*- \[ \]' "$ACTIVE")
# A mission with nothing pending is finished, not something to resume.
if [ "$SOURCE" != "compact" ] && [ "$pending" -gt 0 ]; then
  title=$(sed -n 's/^# Mission:[[:space:]]*//p' "$ACTIVE" | head -1 | tr -d '\r' | cut -c1-120)
  echo "--- Open Mission ---"
  echo "${title:-Untitled}: ${pending} pending task(s) in .mallet/missions/active.md."
  echo "Read it, surface the pending tasks, and ask whether to resume or start fresh."
  echo "--- End Open Mission ---"
fi

# ── Git conventions ─────────────────────────────────────────────────────────
# The persona carries no Git rules: each project states its own in CLAUDE.md or
# .claude/rules/, which Claude Code loads itself and re-reads after compaction.
# A git repository with none gets Mallet's defaults (rules/git.md) for this
# session, and Claude is asked to offer them as .claude/rules/git.md. The check
# looks where Claude Code looks: the project directory and every directory
# above it, then the user-level files. "Has conventions" means the marker
# rules/git.md carries, or a markdown heading naming Git.

RULES="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/rules/git.md"
PROJECT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
GIT_RULES_PATTERN='mallet:git-conventions|^#+ (.*[[:space:]])?git([[:space:]]|$)'
# $1: a directory. True when its CLAUDE.md, CLAUDE.local.md, .claude/CLAUDE.md,
# or any .md under .claude/rules/ (recursive, as Claude Code reads it) matches.
has_git_rules() {
  for f in "$1/CLAUDE.md" "$1/CLAUDE.local.md" "$1/.claude/CLAUDE.md"; do
    [ -f "$f" ] && grep -Eiq "$GIT_RULES_PATTERN" "$f" && return 0
  done
  [ -d "$1/.claude/rules" ] \
    && [ -n "$(find "$1/.claude/rules" -name '*.md' -exec grep -Eil "$GIT_RULES_PATTERN" {} + 2>/dev/null)" ] \
    && return 0
  return 1
}
if [ -f "$RULES" ] && command -v git >/dev/null 2>&1 \
   && git -C "$PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  found=no
  d=$(cd "$PROJECT" && pwd -P); n=0
  while [ -n "$d" ]; do
    has_git_rules "$d" && { found=yes; break; }
    n=$((n + 1)); [ "$n" -ge 32 ] && break
    parent=$(dirname "$d"); [ "$parent" = "$d" ] && break; d=$parent
  done
  [ "$found" = no ] && has_git_rules "$HOME" && found=yes
  if [ "$found" = no ]; then
    echo "--- Git Conventions ---"
    echo "This project states no Git conventions (no heading naming Git in CLAUDE.md, CLAUDE.local.md, or .claude/rules/, here or in a parent directory or ~/.claude). Mallet's defaults apply for this session:"
    grep -v '^<!-- mallet:git-conventions -->$' "$RULES"
    echo "Once the user's first request is handled, offer once to make them the project's own by copying ${RULES} to .claude/rules/git.md (Claude Code loads that file in every session). A project that wants different rules writes its own Git section instead; either stops this notice."
    echo "--- End Git Conventions ---"
  fi
fi

exit 0
