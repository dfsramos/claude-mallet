#!/usr/bin/env bash
# Stop hook: type-checks the TypeScript and PHP files edited this turn (recorded
# by typecheck.sh) once, and hands errors in those files back to Claude so it
# fixes them before ending the turn. Errors elsewhere in the project are left
# out: they predate the turn and would otherwise stop every turn.
#
# Opt-in per project via .mallet/typecheck.enabled, like typecheck.sh.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[ -f "$PROJECT_DIR/.mallet/typecheck.enabled" ] || exit 0

INPUT="$(cat)"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' | tr -cd 'A-Za-z0-9_-')"
[ -n "$SESSION_ID" ] || exit 0
LIST="${TMPDIR:-/tmp}/mallet-typecheck-${SESSION_ID}.list"
[ -s "$LIST" ] || exit 0

# Already continuing because of a Stop hook: let the turn end and keep the list,
# so the next turn's check still covers these files without risking a loop.
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

FILES="$(sort -u "$LIST")"
rm -f "$LIST"
OUTPUT=""

TS_FILES="$(printf '%s\n' "$FILES" | grep -E '\.tsx?$')"
if [ -n "$TS_FILES" ] && [ -f "$PROJECT_DIR/tsconfig.json" ]; then
  # tsc prints paths relative to the project as "path(line,col): error ...".
  PATTERNS="$(printf '%s\n' "$TS_FILES" | sed "s|^$PROJECT_DIR/||; s|\$|(|")"
  TS_OUT="$(cd "$PROJECT_DIR" && npx tsc --noEmit 2>&1 | grep -F -f <(printf '%s\n' "$PATTERNS") | head -20)"
  [ -n "$TS_OUT" ] && OUTPUT+="$TS_OUT"$'\n'
fi

PHP_FILES="$(printf '%s\n' "$FILES" | grep -E '\.php$')"
# A while-read loop rather than mapfile, which bash 3.2 (macOS) lacks; deleted
# files are skipped, since phpstan reports a missing path as an error.
PHP_ARGS=()
while IFS= read -r f; do [ -f "$f" ] && PHP_ARGS+=("$f"); done <<< "$PHP_FILES"
if [ "${#PHP_ARGS[@]}" -gt 0 ] && [ -f "$PROJECT_DIR/vendor/bin/phpstan" ]; then
  PHP_OUT="$(cd "$PROJECT_DIR" && ./vendor/bin/phpstan analyse --no-progress --error-format=raw "${PHP_ARGS[@]}" 2>&1 | head -20)"
  [ -n "$PHP_OUT" ] && OUTPUT+="$PHP_OUT"$'\n'
fi

[ -n "$OUTPUT" ] || exit 0
jq -n --arg c "[typecheck] Errors in files edited this turn — fix them before finishing:"$'\n'"$OUTPUT" \
  '{hookSpecificOutput:{hookEventName:"Stop",additionalContext:$c}}'
exit 0
