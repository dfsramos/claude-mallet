# Task: hooks-setup-skill
Status: pending
Deps: 01, 02

## Goal
Write `.claude/skills/hooks-setup/SKILL.md` — a skill that detects the project stack and registers selected optional hooks in `settings.json` idempotently.

## Behaviour the skill should implement
1. Read `.claude/settings.json` and report which optional hooks (typecheck, push-confirm) are already registered (by checking if their script filenames appear in any existing hook command string)
2. Detect stack: check for `tsconfig.json` or `"typescript"` in `package.json` dependencies (TS); `vendor/bin/phpstan` (PHP)
3. Present available hooks that are not yet registered:
   - **typecheck** — PostToolUse on Edit; requires TS or PHP project
   - **push-confirm** — PreToolUse on Bash; works for any project
4. Ask the user which to enable
5. For each selected:
   a. Verify `.claude/hooks/<name>.sh` exists — if missing, skip and report
   b. Read `settings.json` again (fresh read before edit)
   c. If script path already appears in any command string, skip (idempotent)
   d. Append to the correct event array using Edit (not Write):
      - `typecheck.sh` → `PostToolUse`, matcher `Edit`
      - `push-confirm.sh` → `PreToolUse`, matcher `Bash`
6. Report: which hooks were registered, which were skipped (already present or script missing)

## Notes
- The skill description field must state trigger conditions only
- settings.json uses `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh"` as the command format
- Use Edit, not Write, for any settings.json update
