#!/bin/bash
# PreToolUse hook on Edit and Write:
# - Blocks Write on files that already exist. The persona requires Edit for
#   existing files: Edit sends only the diff; Write re-sends the full content.
# - Asks before Edit changes an existing linter or type-checker config, so a
#   failing check gets fixed in the code rather than loosened in its config.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ] || exit 0

# Exit 2 feeds stderr, not stdout, back to the model as the block reason.
if [ "$TOOL" = "Write" ]; then
  echo "[write-guard] '$FILE_PATH' already exists. Use Edit instead — it sends only the changed lines and costs fewer tokens. Write is reserved for files that do not yet exist (Mallet persona, Tool Preferences)." >&2
  exit 2
fi

if [ "$TOOL" = "Edit" ]; then
  case "$(basename "$FILE_PATH")" in
    .eslintrc|.eslintrc.*|eslint.config.*|.prettierrc|.prettierrc.*|prettier.config.*|\
    biome.json|biome.jsonc|.stylelintrc|.stylelintrc.*|stylelint.config.*|\
    tsconfig.json|tsconfig.*.json|jsconfig.json|\
    ruff.toml|.ruff.toml|mypy.ini|.mypy.ini|.flake8|.pylintrc|\
    phpstan.neon|phpstan.neon.dist|phpstan.dist.neon|psalm.xml|.php-cs-fixer.php|.php-cs-fixer.dist.php|\
    .golangci.yml|.golangci.yaml|.golangci.toml)
      # For "ask", the reason is shown to the user in the permission prompt.
      jq -n --arg r "[write-guard] This edits lint or type-check config ($FILE_PATH). Allow it only if the change is intended; loosening a check to make errors disappear hides them rather than fixing them." \
        '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
      ;;
  esac
fi

exit 0
