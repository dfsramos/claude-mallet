#!/usr/bin/env bash
# PostToolUse hook: records each TypeScript or PHP file edited this turn, for
# typecheck-stop.sh to check once when Claude finishes the turn. A full-project
# check after every edit repeats the same work and reports half-finished
# multi-edit states as errors.
#
# Opt-in per project: the plugin registers this hook everywhere, and it does
# nothing unless the project has a .mallet/typecheck.enabled marker (created by
# the hooks-setup skill). A per-project settings registration would need a
# stable script path, which a versioned plugin cache does not provide.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[ -f "$PROJECT_DIR/.mallet/typecheck.enabled" ] || exit 0

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' | tr -cd 'A-Za-z0-9_-')"

case "$TOOL_NAME" in Edit|Write) ;; *) exit 0 ;; esac
[ -n "$FILE_PATH" ] && [ -n "$SESSION_ID" ] || exit 0
case "${FILE_PATH##*.}" in ts|tsx|php) ;; *) exit 0 ;; esac

echo "$FILE_PATH" >> "${TMPDIR:-/tmp}/mallet-typecheck-${SESSION_ID}.list"
exit 0
