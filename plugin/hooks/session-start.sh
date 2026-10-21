#!/bin/bash
# SessionStart hook (matcher: startup|resume|clear|compact):
#   1. Keeps the statusline copy in CLAUDE_PLUGIN_DATA current.
#                                                         (startup, resume)
#   On resume nothing else runs: the resumed conversation already holds the
#   notices below from when it started.
#   2. Names leftover .mallet/ files that earlier versions read and nothing
#      reads since 2026-10-20, and asks Claude to offer the move once.
#                                                             (startup, clear)
#   3. In a git repository with no Git conventions of its own, prints Mallet's
#      default rules (rules/git.md) and asks Claude to offer them.
#                                                      (startup, clear, compact)
# Updates arrive through the plugin system, so there is no update check here.
# Project skills and open missions are no longer announced here: Claude Code
# loads .claude/skills/ itself, and open work lives in auto memory.
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

# ── Leftover project files ──────────────────────────────────────────────────
# Earlier versions read .mallet/conventions.md and .mallet/overrides/<skill>.md,
# injected .mallet/memory.md and .mallet/lessons.md, listed .mallet/skills/,
# and flagged .mallet/missions/active.md. Since 2026-10-20 nothing does, so a
# project that still keeps its context there loses it without a word unless
# this says so. The migrate skill (retired 2026-10-21) wrote conventions.md
# into every repo it cleaned, so most older projects have one.
# Name what is left, have Claude apply the conventions for this session, and
# ask it to offer the moves once. Runs on startup and clear, which both begin a
# conversation without the earlier notice; stops once the files are gone or
# .mallet/.leftovers-declined exists. No content is printed: a conventions
# file can be long, and Claude reads it on request.

M="${CLAUDE_PROJECT_DIR:-$(pwd)}/.mallet"
if { [ "$SOURCE" = "startup" ] || [ "$SOURCE" = "clear" ]; } && [ -d "$M" ] && [ ! -e "$M/.leftovers-declined" ]; then
  LEFT=""
  if [ -f "$M/conventions.md" ]; then
    LEFT="$LEFT- \`.mallet/conventions.md\` ($(wc -l < "$M/conventions.md" | tr -d ' ') lines): read it now and apply it for this session. Its content belongs in \`CLAUDE.md\` or \`.claude/rules/<topic>.md\`, which Claude Code loads itself.
"
  fi
  names=""
  for f in memory.md lessons.md; do [ -f "$M/$f" ] && names="$names${names:+, }\`.mallet/$f\`"; done
  if [ -n "$names" ]; then
    LEFT="$LEFT- $names: fold into auto memory (a fact becomes a project or reference entry, a lesson a feedback entry; skip what is already recorded), then the user decides whether to delete them.
"
  fi
  names=""
  for f in "$M"/overrides/*.md; do [ -f "$f" ] && names="$names${names:+, }$(basename "$f")"; done
  if [ -n "$names" ]; then
    LEFT="$LEFT- \`.mallet/overrides/\` ($names): each becomes \`.claude/rules/<skill>.md\` holding \"When running \`/mallet:<skill>\`, ...\" lines.
"
  fi
  names=""
  for d in "$M"/skills/*/; do [ -d "$d" ] && names="$names${names:+, }$(basename "$d")"; done
  if [ -n "$names" ]; then
    LEFT="$LEFT- \`.mallet/skills/\` ($names): move each directory to \`.claude/skills/\`, which Claude Code loads itself.
"
  fi
  if [ -f "$M/missions/active.md" ]; then
    LEFT="$LEFT- \`.mallet/missions/active.md\`: an open mission from an earlier version; nothing flags it any more. /mallet:next-steps reads its pending items, and /mallet:reviewing-sessions folds it into an auto memory project entry and archives it.
"
  fi
  names=""
  for f in typecheck.enabled command-guard.enabled .migration-declined; do [ -e "$M/$f" ] && names="$names${names:+, }\`.mallet/$f\`"; done
  if [ -n "$names" ]; then
    LEFT="$LEFT- $names: inert now that the hooks and the legacy-install check they belonged to are gone; delete.
"
  fi
  if [ -n "$LEFT" ]; then
    echo "--- Leftover Mallet Files ---"
    echo "Earlier Mallet versions read or flagged these files; since 2026-10-20 nothing does, so what they hold no longer applies on its own:"
    printf '%s' "$LEFT"
    echo "Once the user's first request is handled, offer once to make the moves above (git mv for tracked files; delete nothing without the user's say). If the user declines, create ${M}/.leftovers-declined so this notice stops."
    echo "--- End Leftover Mallet Files ---"
  fi
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
