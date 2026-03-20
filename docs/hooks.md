# Hooks

Hooks are shell scripts that run automatically in response to Claude Code events. They are registered in `.claude/settings.json`.

## Session Start Hook

**File:** `.claude/hooks/session-start.sh`
**Trigger:** Claude Code session startup

Reads the session ID provided by Claude Code via the hook's stdin JSON and injects it into Claude's context.

### What it does

1. Reads `session_id` from the hook input JSON on stdin
2. Exports it as the `SESSION_ID` environment variable via `$CLAUDE_ENV_FILE`
3. Injects a context message into Claude's conversation via stdout
4. If `.claude/project/memory.md` exists, injects its contents into Claude's context so project memory is available from the first message
5. If `.claude/framework.json` exists and `gh` + `jq` are available, checks the remote repository for a newer commit. If one is found, injects an update notice into Claude's context:
   ```
   --- Framework Update Available ---
   Installed: abc1234 | Latest: def5678 (2026-03-21)
   To update, say: "update the framework from https://github.com/{repo}"
   --- End Framework Update ---
   ```
   Silently skips if `gh` or `jq` are not installed, or if the API call fails.

### Why it exists

The session ID provides a stable reference for the current conversation. It is the actual Claude Code session ID, passed via stdin by the hook runtime. It is used by the [session wrap-up skill](skills.md#session-wrap-up) to identify the session in retrospective output.

The version check ensures users are passively informed of framework updates without having to check manually.

## Adding New Hooks

1. Create a script in `.claude/hooks/`
2. Register it in `.claude/settings.json` under the appropriate event matcher
3. Ensure the script is executable (`chmod +x`)
