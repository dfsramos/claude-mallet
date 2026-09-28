#!/bin/bash
# Session startup hook:
#   1. Keeps the statusline copy in CLAUDE_PLUGIN_DATA current.
#   2. Detects a legacy per-project Mallet install and offers the migrate skill.
# Updates arrive through the plugin system, so there is no update check here.
#
# Project memory is not injected here: Claude Code's auto memory loads its own
# MEMORY.md index at session start.

# ── Statusline copy ─────────────────────────────────────────────────────────
# A statusLine command cannot reference CLAUDE_PLUGIN_ROOT, which changes with
# every plugin version. /mallet:setup points statusLine at this copy in the
# persistent data directory instead, and refreshing it here on every startup
# carries plugin updates through to it.

if [ -n "${CLAUDE_PLUGIN_DATA:-}" ] && [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  SRC="${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh"
  DST="${CLAUDE_PLUGIN_DATA}/statusline.sh"
  if [ -f "$SRC" ] && ! cmp -s "$SRC" "$DST"; then
    mkdir -p "$CLAUDE_PLUGIN_DATA" && cp "$SRC" "$DST.tmp" && mv "$DST.tmp" "$DST"
  fi
fi

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
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] \
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

exit 0
