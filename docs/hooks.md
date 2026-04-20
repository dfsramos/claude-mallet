# Hooks

Hooks are shell scripts that run automatically in response to Claude Code events. They are registered in `.claude/settings.json`.

## Session Start Hook

**File:** `.claude/hooks/session-start.sh`
**Trigger:** Claude Code session startup (`matcher: "startup"`)

Injects project memory and a framework update notice (when available) at session start.

### What it does

1. **Project memory injection.** If `.claude/project/memory.md` exists, echoes its contents wrapped in `--- Project Memory ---` markers so project facts are in context from turn one.
2. **Framework update check.** If `.claude/framework.json` exists and `curl` + `jq` are available, queries the GitHub API for the repo's default branch HEAD. If the local hash differs, emits a `--- Framework Update Available ---` notice instructing Claude to surface it to the user and offer to run the update skill.

Both steps fail silently on any error (missing tools, network failure, unparseable JSON) — a hook failure never disrupts session start.

### Why it exists

Project memory — persistent facts about commands, conventions, and non-obvious behaviours — needs to be in context from turn one, not discovered lazily.

The update check moved from the statusline to this hook because the statusline re-renders continuously (forcing a 5-minute cache to avoid API spam), while session start fires exactly once. Moving the check removes the cache, and delivering the notice via context rather than statusline text means Claude can proactively offer to run the update instead of the user having to notice the tiny status string.

## UserPromptSubmit Hook

**File:** `.claude/hooks/user-prompt-submit.sh`
**Trigger:** Every user message submitted to Claude

Runs two independent checks on every prompt: a session turn counter and a complexity scorer. Designed to be silent for routine work and only speak up when session length or task complexity warrants it.

### What it does

Reads the full hook input JSON on stdin, then:

**Turn counter:**
1. Reads `transcript_path` from the hook input
2. Counts human messages in the JSONL transcript (filters out sidechain and API-error entries)
3. At 50 prompts: injects a soft compaction reminder
4. At 80 prompts and every 20 after: injects a strong compaction warning

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
   Using `bash` explicitly avoids relying on the hook script having the execute bit set on disk. This matters because (a) git may not preserve the bit across platforms (e.g., with `core.fileMode = false`), and (b) tarball extraction and fresh copies can drop permissions until `chmod +x` runs.
