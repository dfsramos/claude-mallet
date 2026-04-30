#!/usr/bin/env bash
# PostToolUse hook: runs a type-checker/linter after Edit and surfaces errors to Claude.
# Supports TypeScript (tsc) and PHP (PHPStan). Advisory only — always exits 0.

INPUT="$(cat)"

TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"

# Only act on Edit calls with a file path.
if [ "$TOOL_NAME" != "Edit" ] || [ -z "$FILE_PATH" ]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

case "$EXT" in
  ts|tsx)
    if [ -f "$PROJECT_DIR/tsconfig.json" ]; then
      OUTPUT="$(cd "$PROJECT_DIR" && npx tsc --noEmit 2>&1 | head -20)"
      if [ -n "$OUTPUT" ]; then
        printf '[typecheck] %s\n' "$OUTPUT"
      fi
    fi
    ;;
  php)
    PHPSTAN="$PROJECT_DIR/vendor/bin/phpstan"
    if [ -f "$PHPSTAN" ]; then
      OUTPUT="$(cd "$PROJECT_DIR" && ./vendor/bin/phpstan analyse "$FILE_PATH" --no-progress 2>&1 | head -20)"
      if [ -n "$OUTPUT" ]; then
        printf '[typecheck] %s\n' "$OUTPUT"
      fi
    fi
    ;;
  *)
    exit 0
    ;;
esac

exit 0
