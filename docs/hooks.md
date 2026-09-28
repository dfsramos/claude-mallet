# Hooks

Hooks are shell scripts that run automatically in response to Claude Code events. They live at `plugin/hooks/` and ship with the plugin — every user runs the same scripts, registered in `plugin/hooks/hooks.json` via `${CLAUDE_PLUGIN_ROOT}`, which resolves to the installed plugin version at runtime.

Each hook locates its *data* through `$CLAUDE_PROJECT_DIR`, so the one global script reads whichever project's `.mallet/` state is current.

## A fact that shapes every hook here

**For `PreToolUse`, `PostToolUse`, and `PreCompact`, plain stdout on exit 0 is written only to the debug log — it never reaches the model.** Only `UserPromptSubmit` and `SessionStart` stdout is added to context. This is why `typecheck.sh` (PostToolUse) returns its findings as JSON `additionalContext` instead of printing them, and why `write-guard.sh` (PreToolUse) writes its block reason to stderr and exits `2` — a blocking exit's stderr is fed back to the model as the reason, regardless of event type.

## Registration

All six scripts are registered in one file, `plugin/hooks/hooks.json`:

| Hook | Event | Matcher |
|---|---|---|
| `persona.sh` | SessionStart | `startup\|resume\|clear\|compact` |
| `session-start.sh` | SessionStart | `startup` |
| `post-compact.sh` | SessionStart | `compact` |
| `user-prompt-submit.sh` | UserPromptSubmit | *(none — every prompt)* |
| `write-guard.sh` | PreToolUse | `Write` |
| `typecheck.sh` | PostToolUse | `Edit\|Write` |

There is no separate opt-in registration tier at the settings level any more — the plugin registers everything globally. `typecheck.sh` is opt-in in effect only, gated on a per-project marker file (see below), because a per-project `settings.json` registration would need a stable script path, which a versioned plugin cache does not provide.

## Persona Hook

**File:** `plugin/hooks/persona.sh`
**Trigger:** `SessionStart`, matcher `startup|resume|clear|compact`

Injects the Mallet persona (`plugin/persona/PERSONA.md`) as session context. This is the only way the plugin delivers its directives — **plugins cannot ship a `CLAUDE.md`** — and it fires on `clear` and `compact` too, since both drop earlier context that would otherwise carry the persona with it.

Hook stdout over 10,000 characters is replaced by a file path and a 2,000-character preview instead of being injected whole, so `PERSONA.md` must stay under that. It is currently well under (`tests/test-15-plugin.sh` enforces under 9,800 characters as a safety margin). If `${CLAUDE_PLUGIN_ROOT}` is unset (e.g. run standalone), it falls back to resolving the script's own directory.

## Session Start Hook

**File:** `plugin/hooks/session-start.sh`
**Trigger:** `SessionStart`, matcher `startup`

Two independent jobs, both cheap and network-free:

1. **Statusline refresh.** A `statusLine` command cannot reference `${CLAUDE_PLUGIN_ROOT}`, which changes with every plugin version, so `/mallet:setup` points `statusLine` at a copy in `${CLAUDE_PLUGIN_DATA}` instead. This hook keeps that copy current by comparing it against `${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh` on every startup and overwriting it (via a temp file + `mv`) when they differ, so a plugin update reaches the statusline without a manual step.
2. **Legacy per-project install detection.** If the current project still carries a per-project Mallet payload — `.claude/framework.json`, or both `.claude/skills/update/SKILL.md` and `.claude/agents/_contract.md` — prints a notice offering the `migrate` skill. Two exemptions prevent it nagging forever: the install's own project root (identified by `.claude/settings.fragment.json` / `.claude/install-payload.sh`, which only this source repo has), and any project where `.mallet/.migration-declined` exists.

There is no update check here any more — updates arrive through the plugin system itself, so the GitHub-polling logic and its 24-hour cache are gone.

## Post-Compact Hook

**File:** `plugin/hooks/post-compact.sh`
**Trigger:** `SessionStart`, matcher `compact`

Restores working state immediately after a compaction, in the same session: current git branch, uncommitted changes (`git status --short`, up to 15 lines), the last 5 commits, the list of mission files present, and the full contents of `.mallet/missions/active.md` if one exists.

This replaces the old `pre-compact.sh` for two reasons: `PreCompact` stdout never reaches the model (see the fact above), so its context injection was silently doing nothing; and its snapshot file (`.mallet/compact-snapshot.md`) could leak into a later, unrelated session if that session started before the file was consumed. Emitting fresh state from a `SessionStart` hook instead means there is no file to persist and nothing to leak.

## UserPromptSubmit Hook

**File:** `plugin/hooks/user-prompt-submit.sh`
**Trigger:** Every user message submitted to Claude

Two independent checks, both derived from the transcript on stdin:

**Session-watch (turn counter).** Counts human-typed prompts only — transcripts mark them with `origin.kind == "human"`; tool results, agent hand-backs, and skill expansions are also stored as role `user` and are excluded, since counting them previously inflated the total roughly 7x. At 50 prompts, injects a soft compaction reminder; at 80 and every 20 after, a stronger warning.

**Calibrate.** Injects a `[calibrate] active model: X; effort: Y` line when either value changes since the last prompt. Neither value is visible to this hook directly, so it reads them from a per-session state file (`${TMPDIR:-/tmp}/mallet-calibrate-<session_id>.json`) that `statusline.sh` writes on every render from the session JSON's `model.id` and `effort.level` — the latter tracks mid-session `/effort` changes and is absent when the active model has no effort parameter. If no such state file exists (no Mallet statusline registered), it falls back to `effortLevel` in the most specific `settings.local.json`/`settings.json` it can find, and says so, since that fallback cannot see live `/effort` changes. The line is written once per change, tracked via a sibling `.last` file, so it costs nothing on unchanged turns.

## Write Guard Hook

**File:** `plugin/hooks/write-guard.sh`
**Trigger:** `PreToolUse`, matcher `Write`

Blocks `Write` calls on files that already exist — the persona requires `Edit` for existing files, since `Edit` sends only the changed lines while `Write` re-sends the whole file. Reads `tool_input.file_path`; if it points to an existing file, writes the block reason to **stderr** and exits `2`. Exit 2 is what feeds the message back to the model as the block reason — plain stdout would not, per the fact above. New files (`Write` creating something that doesn't exist) pass through with exit 0.

## Typecheck Hook

**File:** `plugin/hooks/typecheck.sh`
**Trigger:** `PostToolUse`, matcher `Edit|Write`
**Activation:** opt-in per project via a marker file, not a settings registration

The plugin registers this hook for every project, but it does nothing unless `.mallet/typecheck.enabled` exists at the project root (created by the `hooks-setup` skill). A per-project `settings.json` hook registration would need to reference a stable script path, and the plugin cache path changes with every version — the marker file is what makes the opt-in per-project instead.

When active: detects the edited file's extension and runs `npx tsc --noEmit` (if `tsconfig.json` exists, for `.ts`/`.tsx`) or `vendor/bin/phpstan analyse <file> --no-progress` (if the binary exists, for `.php`), capped to the first 20 lines of output. Because plain `PostToolUse` stdout never reaches the model, results are returned as JSON: `{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "[typecheck] ..."}}`. Always exits 0 — advisory only, never blocks.

## Removed Hooks

Three hooks from earlier versions are gone, not carried forward as opt-in:

| Hook | Why removed |
|---|---|
| `pre-compact.sh` | Its `PreCompact` stdout never reached the model, and its snapshot file could leak into an unrelated later session — see Post-Compact Hook above |
| `push-confirm.sh` | Superseded by a `permissions.ask` rule (`"Bash(git push *)"`) in settings, which Claude Code enforces natively |
| `explore-redirect.sh` | Superseded by the built-in Explore agent for broad search; its Graphify pointer was niche enough not to warrant a dedicated hook |

Regex-based complexity scoring (the old `task-calibrate` trigger) and `[ultracode]` scoring are also gone from `user-prompt-submit.sh`. Calibration is now a model-side judgment call — see the Task Calibration directive in [`directives.md`](directives.md) — because hooks cannot see the active model or effort level, and a prompt-type hook cannot itself decide whether a task's *content* warrants a change; only the model can.

## Adding New Hooks

1. Create the script in `plugin/hooks/`.
2. Register it in `plugin/hooks/hooks.json` under the right event, using an explicit `bash "${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh"` command:
   ```json
   { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/my-hook.sh\"" }
   ```
   Always use `${CLAUDE_PLUGIN_ROOT}` for the script's own path — it resolves to the installed plugin version. Use `$CLAUDE_PROJECT_DIR` *inside* the script to locate that project's data, never for the script path itself.
3. If the hook should be opt-in per project rather than always active, gate it on a `.mallet/<name>.enabled` marker file the way `typecheck.sh` does, and extend the `hooks-setup` skill to toggle it. Do not try to register it only in some projects' `settings.json` — the plugin cache path is not stable enough for that.
4. Remember which event types reach the model as plain stdout (`UserPromptSubmit`, `SessionStart`) and which do not (`PreToolUse`, `PostToolUse`, `PreCompact`) — pick the delivery mechanism (stdout, JSON `additionalContext`, or stderr + exit 2) accordingly.
5. Update this file and `tests/` — hook and script behaviour is covered by `tests/test-*.sh`; run `bash tests/run.sh` before committing.
