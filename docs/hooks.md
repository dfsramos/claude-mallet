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

### Why it exists

The session ID provides a stable reference for tracking work across a session. It is used by the [session wrap-up skill](skills.md#session-wrap-up) to name session records and link retrospective output to a specific session.

## Adding New Hooks

1. Create a script in `.claude/hooks/`
2. Register it in `.claude/settings.json` under the appropriate event matcher
3. Ensure the script is executable (`chmod +x`)
