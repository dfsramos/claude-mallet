# Task: typecheck-hook
Status: pending
Deps: —

## Goal
Write `.claude/hooks/typecheck.sh` — a PostToolUse hook that runs after Edit on source files and surfaces linter errors to Claude.

## Behaviour
- Reads `tool_name` and `tool_input.file_path` from stdin JSON
- Exits 0 immediately if tool is not Edit or file_path is empty
- Detects file extension:
  - `.ts` / `.tsx`: if `tsconfig.json` exists in `$CLAUDE_PROJECT_DIR`, runs `npx tsc --noEmit`, pipes output through `head -20`
  - `.php`: if `vendor/bin/phpstan` exists, runs `./vendor/bin/phpstan analyse "$FILE_PATH" --no-progress`, pipes through `head -20`
  - anything else: exits 0 silently
- Only outputs if the linter produced non-empty output
- Prefixes output with `[typecheck]`
- Always exits 0 (advisory — never blocks)

## Notes
- Use `2>&1` in command substitution to capture stderr alongside stdout
- Check command existence with `command -v` or file existence before running
- `$CLAUDE_PROJECT_DIR` may be unset in some environments; fall back to `$(pwd)` if empty
