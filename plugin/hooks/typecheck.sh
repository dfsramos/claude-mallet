#!/usr/bin/env bash
# PostToolUse hook: runs a type-checker/linter after Edit or Write and surfaces
# errors to Claude. Supports TypeScript (tsc) and PHP (PHPStan). Advisory only —
# always exits 0.
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

case "$TOOL_NAME" in Edit|Write) ;; *) exit 0 ;; esac
[ -n "$FILE_PATH" ] || exit 0

# Plain PostToolUse stdout goes to the debug log only; the model sees a
# PostToolUse hook's output only as JSON additionalContext.
emit() {
  jq -n --arg c "[typecheck] $1" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
}

EXT="${FILE_PATH##*.}"

case "$EXT" in
  ts|tsx)
    if [ -f "$PROJECT_DIR/tsconfig.json" ]; then
      OUTPUT="$(cd "$PROJECT_DIR" && npx tsc --noEmit 2>&1 | head -20)"
      if [ -n "$OUTPUT" ]; then
        emit "$OUTPUT"
      fi
    fi
    ;;
  php)
    PHPSTAN="$PROJECT_DIR/vendor/bin/phpstan"
    if [ -f "$PHPSTAN" ]; then
      OUTPUT="$(cd "$PROJECT_DIR" && ./vendor/bin/phpstan analyse "$FILE_PATH" --no-progress 2>&1 | head -20)"
      if [ -n "$OUTPUT" ]; then
        emit "$OUTPUT"
      fi
    fi
    ;;
  *)
    exit 0
    ;;
esac

exit 0
