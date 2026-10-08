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
OUTPUT=""

TS_FILES="$(printf '%s\n' "$FILES" | grep -E '\.tsx?$')"
# The project's own tsc only: without a local install, `npx tsc` runs
# non-interactively, assumes --yes, and fetches the unrelated `tsc` package.
# Walks up so a workspace package finds a tsc hoisted to the monorepo root.
# Yarn PnP installs have no node_modules/.bin and are skipped.
TSC=""
d="$PROJECT_DIR"
while [ -n "$d" ]; do
  [ -x "$d/node_modules/.bin/tsc" ] && { TSC="$d/node_modules/.bin/tsc"; break; }
  [ "$d" = "/" ] && break
  d="$(dirname "$d")"
done
if [ -n "$TS_FILES" ] && [ -f "$PROJECT_DIR/tsconfig.json" ] && [ -n "$TSC" ]; then
  # tsc prints paths relative to the project as "path(line,col): error ...".
  # Prefix stripping in bash, not sed, so the path is never read as a regex.
  PATTERNS=""
  while IFS= read -r f; do PATTERNS+="${f#"$PROJECT_DIR/"}("$'\n'; done <<< "$TS_FILES"
  TS_OUT="$(cd "$PROJECT_DIR" && "$TSC" --noEmit 2>&1 | grep -F -f <(printf '%s' "$PATTERNS") | head -20)"
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

# Cleared only once the checks finish: if the hook timeout kills a slow check,
# the list survives and the next turn's Stop checks these files again.
rm -f "$LIST"
[ -n "$OUTPUT" ] || exit 0
jq -n --arg c "[typecheck] Errors in files edited this turn — fix them before finishing:"$'\n'"$OUTPUT" \
  '{hookSpecificOutput:{hookEventName:"Stop",additionalContext:$c}}'
exit 0
