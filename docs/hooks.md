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

## UserPromptSubmit Hook

**File:** `.claude/hooks/user-prompt-submit.sh`
**Trigger:** Every user message submitted to Claude

Runs two independent checks on every prompt: a session turn counter and a complexity scorer. Designed to be silent for routine work and only speak up when session length or task complexity warrants it.

### What it does

Reads the full hook input JSON on stdin, then:

**Turn counter:**
1. Reads `session_id` from the hook input
2. Increments a per-session counter stored at `/tmp/ai-framework-turns-<session_id>`
3. Writes the `session_id` to `${CLAUDE_PROJECT_DIR}/.claude/sessions/.current-id` (consumed by the statusline)
4. At 50 prompts: injects a soft compaction reminder
5. At 80 prompts and every 20 after: injects a strong compaction warning

**Complexity scorer:**
1. Reads `prompt` from the hook input
2. Scores the prompt on three signals:
   - **Architectural/design keywords** (`architect`, `redesign`, `rethink`, `overhaul`, `refactor`, `strategy`, `tradeoff`, `migrate`, `evaluate`, `pros and cons`, `which approach`, `from scratch`, etc.) — +2 points
   - **Planning/scope keywords** (`should I/we`, `plan the/a`, `design the/a`, `how should we structure`, `cross-cutting`, `system-wide`, etc.) — +2 points
   - **Long prompt** (> 80 words) — +1 point
3. If `score >= 3`: injects a one-line flag instructing Claude to invoke the `task-calibrate` skill before proceeding
4. Otherwise: exits silently

### Why it exists

The hook runs two passive guardrails per prompt without burdening every interaction.

The turn counter catches runaway sessions — the primary driver of token costs. Long sessions account for ~87% of output tokens. The 50-prompt soft reminder and 80-prompt hard warning give Claude the signal to suggest `/compact` before the session becomes expensive.

The complexity scorer acts as a lightweight tripwire: when architectural signals coincide, it surfaces `task-calibrate` so Claude can assess whether Opus would be a better fit. The threshold (≥ 3) is deliberately conservative — two strong signals, or one signal plus a long prompt, must coincide before anything is injected.

## Adding New Hooks

1. Create a script in `.claude/hooks/`
2. Register it in `.claude/settings.json` under the appropriate event matcher using `bash "..."` invocation:
   ```json
   { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/my-hook.sh\"" }
   ```
   Using `bash` explicitly avoids relying on the execute bit, which git does not track in this repo (`core.fileMode = false`).
