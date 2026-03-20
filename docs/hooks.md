# Hooks

Hooks are shell scripts that run automatically in response to Claude Code events. They are registered in `.claude/settings.json`.

## Session Start Hook

**File:** `.claude/hooks/session-start.sh`
**Trigger:** Claude Code session startup

Generates a unique session identifier in the format `adjective-noun-verb-timestamp` (e.g., `tall-pine-lifts-7488`).

### What it does

1. Builds a random 3-word ID from built-in word lists, appended with a 4-digit timestamp
2. Exports it as the `SESSION_ID` environment variable
3. Writes it to `.claude/sessions/.current`
4. Injects a context message into Claude's conversation via stdout
5. If `.claude/project/memory.md` exists, injects its contents into Claude's context so project memory is available from the first message
6. If `.claude/framework.json` exists and `gh` + `jq` are available, checks the remote repository for a newer commit. If one is found, injects an update notice into Claude's context:
   ```
   --- Framework Update Available ---
   Installed: abc1234 | Latest: def5678 (2026-03-21)
   To update, say: "update the framework from https://github.com/{repo}"
   --- End Framework Update ---
   ```
   Silently skips if `gh` or `jq` are not installed, or if the API call fails.

### Why it exists

The session ID provides a stable reference for tracking work across a session. It is used by the [session wrap-up skill](skills.md#session-wrap-up) to name session records and link retrospective output to a specific session.

The version check ensures users are passively informed of framework updates without having to check manually.

## Adding New Hooks

1. Create a script in `.claude/hooks/`
2. Register it in `.claude/settings.json` under the appropriate event matcher
3. Ensure the script is executable (`chmod +x`)
