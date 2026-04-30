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

## Write Guard Hook

**File:** `.claude/hooks/write-guard.sh`
**Trigger:** `PreToolUse` — fires before every `Write` tool call (`matcher: "Write"`)

Blocks `Write` calls on files that already exist. CLAUDE.md requires `Edit` for existing files; `Write` is reserved for new files only. This hook enforces that rule at the tooling level.

### What it does

1. Reads the hook input JSON from stdin.
2. Extracts `tool_name` and `tool_input.file_path`.
3. If `file_path` points to an existing file, outputs a message directing Claude to use `Edit`, then exits 2 — which blocks the tool call before it executes.
4. If the file does not exist (Write is creating a new file), exits 0 and the call proceeds normally.

### Why it exists

`Edit` sends only the changed lines; `Write` re-sends the full file content, roughly doubling output tokens per operation. CLAUDE.md already states the preference, but a directive alone relies on Claude remembering it every time. A blocking hook enforces it mechanically — Claude receives the block reason and retries with `Edit`.

The hook only fires on `PreToolUse` for `Write`, so it adds zero overhead to all other tool calls.

## Typecheck Hook

**File:** `.claude/hooks/typecheck.sh`
**Trigger:** `PostToolUse` — fires after every `Edit` tool call (`matcher: "Edit"`)
**Activation:** opt-in via `/hooks-setup` — not registered by default

Runs the project's type-checker or linter after each file edit and surfaces errors directly into Claude's context, catching type errors at the moment they're introduced rather than at the end of a session.

### What it does

1. Reads `tool_name` and `tool_input.file_path` from the hook input JSON.
2. Exits 0 immediately if the tool is not `Edit` or `file_path` is empty.
3. Detects the file extension and runs the appropriate linter:
   - `.ts` / `.tsx` — if `tsconfig.json` exists in `$CLAUDE_PROJECT_DIR`, runs `npx tsc --noEmit 2>&1 | head -20`
   - `.php` — if `vendor/bin/phpstan` exists, runs `phpstan analyse <file> --no-progress 2>&1 | head -20`
   - All other extensions — exits 0 silently
4. Outputs non-empty linter results prefixed with `[typecheck]`.
5. Always exits 0 — advisory only, never blocks.

### Why it exists

Linter errors that surface only after a multi-file session require backtracking. Running the type-checker after each edit closes the feedback loop to the turn level, catching errors while the relevant context is still in Claude's window.

## Push-Confirm Hook

**File:** `.claude/hooks/push-confirm.sh`
**Trigger:** `PreToolUse` — fires before every `Bash` tool call (`matcher: "Bash"`)
**Activation:** opt-in via `/hooks-setup` — not registered by default

Warns Claude before any `git push` executes and requires it to verify the push was explicitly requested, preventing pushes that fire as side effects of autonomous multi-step tasks.

### What it does

1. Reads `tool_name` and `tool_input.command` from the hook input JSON.
2. Exits 0 immediately if the tool is not `Bash`.
3. Checks whether the command contains `git push` using `grep -qE '(^|[;&|]\s*)git\s+push(\s|$)'`.
4. If matched: outputs a `[push-confirm]` warning with the full command and instructs Claude to verify intent before proceeding.
5. Always exits 0 — advisory only, never blocks.

### Why advisory and not blocking

A blocking hook (exit 2) creates an infinite retry loop: after the user confirms, Claude re-runs the command, the hook fires again and blocks again. An advisory hook instead injects the warning into Claude's context; Claude reads it, verifies intent against the conversation, and either proceeds or stops and asks.

## Hook Tiers

The framework ships hooks in two tiers:

**Default hooks** — registered in `settings.json` at install time, active in every project:
- `session-start.sh` — memory injection and update check
- `user-prompt-submit.sh` — complexity scorer and turn counter
- `write-guard.sh` — blocks Write on existing files

**Optional hooks** — scripts are distributed by the framework but not registered by default; activated per-project via `/hooks-setup`:
- `typecheck.sh` — PostToolUse linter for TypeScript and PHP projects
- `push-confirm.sh` — PreToolUse warning before git push

## Adding New Hooks

1. Create a script in `.claude/hooks/`
2. Register it in `.claude/settings.json` under the appropriate event matcher using `bash "..."` invocation:
   ```json
   { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/my-hook.sh\"" }
   ```
   Using `bash` explicitly avoids relying on the hook script having the execute bit set on disk. This matters because (a) git may not preserve the bit across platforms (e.g., with `core.fileMode = false`), and (b) tarball extraction and fresh copies can drop permissions until `chmod +x` runs.
