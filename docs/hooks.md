# Hooks

Hooks are shell scripts that run automatically in response to Claude Code events. They are registered in `.claude/settings.json`.

## Session Start Hook

**File:** `.claude/hooks/session-start.sh`
**Trigger:** Claude Code session startup

Reads the session ID provided by Claude Code via the hook's stdin JSON and injects it into Claude's context.

### What it does

1. Reads `session_id` from the hook input JSON on stdin
2. Exports it as the `SESSION_ID` environment variable via `$CLAUDE_ENV_FILE`
3. If `.claude/framework.json` exists, outputs a MOTD banner before the session ID:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     AI Framework
     Version:   abc1234  ·  installed 2026-03-20
     Repo:      https://github.com/{owner}/{repo}
     Update:    def5678 (2026-03-25) available — say "update the framework"
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```
   The `Update:` line is omitted when already on the latest commit. Silently skips the banner if `jq` is not installed. Silently skips the update check if `gh` is not installed or the API call fails.
4. Injects the session ID into Claude's conversation via stdout
5. If `.claude/project/memory.md` exists, injects its contents into Claude's context so project memory is available from the first message

### Why it exists

The MOTD confirms the framework is active and makes the installed version immediately visible without having to inspect `framework.json`.

The session ID provides a stable reference for the current conversation. It is the actual Claude Code session ID, passed via stdin by the hook runtime. It is used by the [session wrap-up skill](skills.md#session-wrap-up) to identify the session in retrospective output.

The version check ensures users are passively informed of framework updates without having to check manually.

## Adding New Hooks

1. Create a script in `.claude/hooks/`
2. Register it in `.claude/settings.json` under the appropriate event matcher using `bash "..."` invocation:
   ```json
   { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/my-hook.sh\"" }
   ```
   Using `bash` explicitly avoids relying on the execute bit, which git does not track in this repo (`core.fileMode = false`).
