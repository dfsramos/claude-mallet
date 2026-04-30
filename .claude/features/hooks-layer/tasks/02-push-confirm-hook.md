# Task: push-confirm-hook
Status: pending
Deps: —

## Goal
Write `.claude/hooks/push-confirm.sh` — a PreToolUse hook that warns Claude before any `git push` command runs via Bash.

## Behaviour
- Reads `tool_name` and `tool_input.command` from stdin JSON
- Exits 0 immediately if tool is not Bash
- Checks if the command contains `git push` (with any flags, remotes, or branch args)
  - Match pattern: `git push` appearing at start or after a shell separator (`; | & &&`)
- If matched: outputs a warning with the full command and instructs Claude to verify the push was explicitly requested before proceeding
- Always exits 0 (advisory — never blocks, to avoid infinite retry loop when user confirms)

## Notes
- Use grep -qE with pattern `(^|[;&|]\s*)git\s+push(\s|$)` to match reliably
- Include the actual command in the output so Claude and the user can see exactly what is being warned about
