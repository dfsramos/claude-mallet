# Hooks

Hooks are shell scripts that run automatically in response to Claude Code events. They live at `plugin/hooks/` and ship with the plugin — every user runs the same scripts, registered in `plugin/hooks/hooks.json` via `${CLAUDE_PLUGIN_ROOT}`, which resolves to the installed plugin version at runtime.

Each hook locates its *data* through `$CLAUDE_PROJECT_DIR`, so the one global script reads whichever project is current.

## A fact that shapes every hook here

**For `PreToolUse`, `PostToolUse`, and `PreCompact`, plain stdout on exit 0 is written only to the debug log — it never reaches the model.** Only `UserPromptSubmit` and `SessionStart` stdout is added to context. Every Mallet hook is now a `SessionStart` hook, the one event where a plugin can put text in front of the model without a JSON envelope. A hook on any other event has to answer with JSON `additionalContext` or a `permissionDecision`, or block by writing to stderr and exiting `2` (a blocking exit's stderr is fed back to the model as the reason, regardless of event type). The removed hooks below worked that way, and the rule applies to any new one.

## Registration

Three scripts are registered in one file, `plugin/hooks/hooks.json`:

| Hook | Event | Matcher |
|---|---|---|
| `persona.sh` | SessionStart | `startup\|resume\|clear\|compact` |
| `session-start.sh` | SessionStart | `startup\|resume\|clear\|compact` |
| `post-compact.sh` | SessionStart | `compact` |

The plugin registers every hook globally; there is no per-project opt-in tier, because a per-project `settings.json` registration would need a stable script path, which a versioned plugin cache does not provide. A behaviour that should not run everywhere does not belong in a plugin hook: a user-level `permissions` rule or setting does that job natively (see Removed Hooks).

## Persona Hook

**File:** `plugin/hooks/persona.sh`
**Trigger:** `SessionStart`, matcher `startup|resume|clear|compact`

Injects the Mallet persona (`plugin/persona/PERSONA.md`) as session context. This is the only way the plugin delivers its directives — **plugins cannot ship a `CLAUDE.md`** — and it fires on `clear` and `compact` too, since both drop earlier context that would otherwise carry the persona with it.

Hook stdout over 10,000 characters is replaced by a file path and a 2,000-character preview instead of being injected whole, so `PERSONA.md` must stay under that. It is currently well under (`tests/test-15-plugin.sh` enforces under 9,800 characters as a safety margin). If `${CLAUDE_PLUGIN_ROOT}` is unset (e.g. run standalone), it falls back to resolving the script's own directory.

## Session Start Hook

**File:** `plugin/hooks/session-start.sh`
**Trigger:** `SessionStart`, matcher `startup|resume|clear|compact`; the hook reads `source` from its input (with `sed`, so it works without `jq`) to decide which jobs run. On `resume` only the statusline refresh runs: the resumed conversation already holds the leftover-files and Git conventions notices from when it started.

Three independent jobs, all cheap and network-free:

1. **Statusline refresh** (`startup`, `resume`). A `statusLine` command cannot reference `${CLAUDE_PLUGIN_ROOT}`, which changes with every plugin version, so `/mallet:setup` points `statusLine` at a copy in `${CLAUDE_PLUGIN_DATA}` instead. This hook keeps that copy current by comparing it against `${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh` on every startup and resume and overwriting it (via a temp file + `mv`) when they differ, so a plugin update reaches the statusline without a manual step. A resume loads the current plugin version too, so it refreshes as well; otherwise `claude --resume` kept the old statusline.
2. **Leftover project files** (`startup`, `clear`). Earlier versions read `.mallet/conventions.md` and `.mallet/overrides/<skill>.md`, injected `.mallet/memory.md` and `.mallet/lessons.md`, listed `.mallet/skills/`, and flagged `.mallet/missions/active.md`; since 2026-10-20 nothing does, and the `migrate` skill (retired 2026-10-21) had written `conventions.md` into every repo it cleaned, so a project that still keeps its context there would lose it without a word. When `.mallet/` exists and `.mallet/.leftovers-declined` does not, the hook names whatever is left, one line each with where it belongs now: `conventions.md` with its line count (Claude reads it and applies it for the session; the content belongs in `CLAUDE.md` or `.claude/rules/<topic>.md`), `overrides/*.md` (`.claude/rules/<skill>.md`), `memory.md` and `lessons.md` (fold into auto memory), `skills/*/` (`.claude/skills/`), `missions/active.md` (`next-steps` reads it, `reviewing-sessions` folds it into auto memory and archives it), and the inert `typecheck.enabled`, `command-guard.enabled` and `.migration-declined` markers (delete). No file content is printed. Claude is told to offer the moves once after the first request (`git mv` for tracked files, delete nothing unasked) and to create `.mallet/.leftovers-declined` if the user declines, which silences the notice. It runs on `clear` because that starts a new conversation without the earlier notice, and not on `compact`, which keeps it. A `.mallet/` holding none of these prints nothing. Measured size of the notice in a repo with three leftovers: 988 characters, about 250 tokens.
3. **Git conventions** (`startup`, `clear`, `compact`). The persona carries no Git rules: a project states its own in `CLAUDE.md` or `.claude/rules/`, which Claude Code loads itself and re-reads after compaction. In a git repository (`git rev-parse --is-inside-work-tree` on the project directory; silent without `git`), the hook looks for a markdown heading naming Git as a word (`## Git`, `## Git workflow`; `## GitHub Actions` does not count) or the `<!-- mallet:git-conventions -->` marker that `plugin/rules/git.md` carries, in `CLAUDE.md`, `CLAUDE.local.md`, `.claude/CLAUDE.md`, and every `.md` under `.claude/rules/` (recursive, as Claude Code reads it), in the project directory, each directory above it (capped at 32 levels), and `$HOME`. When nothing matches it prints `plugin/rules/git.md` without its marker line as the session's defaults, and tells Claude to offer once, after the first request is handled, to copy that file to `.claude/rules/git.md`; a project that wants different rules writes its own Git section instead. It runs on `clear` and `compact` too, because both drop the earlier notice. The pattern is POSIX ERE without `\b`, so BSD grep matches it. Measured cost of the notice when it fires: 221 tokens.

There is no update check here — updates arrive through the plugin system itself, so the GitHub-polling logic and its 24-hour cache are gone.

Two jobs were removed on 2026-10-20. Listing `.mallet/skills/` is gone because project skills belong in `.claude/skills/`, which Claude Code loads itself. Flagging an open `.mallet/missions/active.md` is gone because open multi-session work lives in auto memory, whose index Claude Code loads at every session start; `reviewing-sessions` writes it. The leftover-files job names both while they are still present. The legacy per-project install check went on 2026-10-21 with the `migrate` skill, once every known user had moved to the plugin; `.mallet/.migration-declined` is now one of the inert markers the leftover-files job names.

## Post-Compact Hook

**File:** `plugin/hooks/post-compact.sh`
**Trigger:** `SessionStart`, matcher `compact`

Restores working state immediately after a compaction, in the same session: current git branch, uncommitted changes (`git status --short`, up to 15 lines), and the last 5 commits. Nothing else: Claude Code re-reads `CLAUDE.md`, `.claude/rules/` and auto memory after compaction itself, and the persona hook re-injects the persona. It no longer prints a mission file (2026-10-20).

This replaces the old `pre-compact.sh` for two reasons: `PreCompact` stdout never reaches the model (see the fact above), so its context injection was silently doing nothing; and its snapshot file (`.mallet/compact-snapshot.md`) could leak into a later, unrelated session if that session started before the file was consumed. Emitting fresh state from a `SessionStart` hook instead means there is no file to persist and nothing to leak.

## Removed Hooks

Hooks from earlier versions are gone, not carried forward as opt-in. Each one's job is done natively now:

| Hook | Removed | Replacement |
|---|---|---|
| `pre-compact.sh` | 2026-10 | `post-compact.sh` above: its `PreCompact` stdout never reached the model, and its snapshot file could leak into an unrelated later session |
| `push-confirm.sh` | 2026-10 | A `permissions.ask` rule (`"Bash(git push *)"`) in settings, which Claude Code enforces natively |
| `explore-redirect.sh` | 2026-10 | The built-in Explore agent for broad search; its Graphify pointer was niche enough not to warrant a dedicated hook |
| `user-prompt-submit.sh` | 2026-10-20 | Its session-watch reminder (a `[session-watch]` notice at 150k context tokens and each further 50k) is replaced by the `autoCompactWindow` setting or `/autocompact`, which compacts at a chosen context size instead of asking. Its `[calibrate]` model-and-effort line went with the Task Calibration directive; nothing replaces it |
| `write-guard.sh` | 2026-10-20 | Claude Code prefers `Edit` over `Write` on an existing file by itself. Its ask before edits to lint or type-check config is a set of `permissions.ask` rules such as `Edit(//**/.eslintrc*)`, `Edit(//**/tsconfig*.json)`, `Edit(//**/phpstan.neon*)` |
| `command-guard.sh` | 2026-10-20 | `permissions.deny` for `Bash(git * --no-verify*)` and `Bash(git commit -n *)` (the one rule native permissions did not already cover), `permissions.ask` for the destructive commands a prompt is wanted for (`Bash(git push --force*)`, `Bash(git reset --hard*)`, `Bash(rm -rf *)`, …). The `.mallet/command-guard.enabled` marker is inert |
| `typecheck.sh`, `typecheck-stop.sh` | 2026-10-20 | The official language server plugins, `claude plugin install typescript-lsp@claude-plugins-official` and `php-lsp@claude-plugins-official`, which report diagnostics after every edit; they need `typescript-language-server` and `intelephense` on `PATH`, as the hooks needed a local `tsc` and `phpstan`. The `.mallet/typecheck.enabled` marker is inert |

## Adding New Hooks

1. Check first that nothing native does the job: a `permissions` rule, a setting, an official plugin. `.claude/rules/hooks.md` in this repo states the bar a hook has to clear, and the portability and output-channel rules it must follow.
2. Create the script in `plugin/hooks/`.
3. Register it in `plugin/hooks/hooks.json` under the right event, using an explicit `bash "${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh"` command:
   ```json
   { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/my-hook.sh\"" }
   ```
   Always use `${CLAUDE_PLUGIN_ROOT}` for the script's own path — it resolves to the installed plugin version. Use `$CLAUDE_PROJECT_DIR` *inside* the script to locate that project's data, never for the script path itself.
4. Every plugin hook is always-on in every project. A behaviour that only some projects want belongs in the user's or project's settings, not in the plugin; do not try to register a hook only in some projects' `settings.json`, since the plugin cache path is not stable enough for that.
5. Remember which event types reach the model as plain stdout (`UserPromptSubmit`, `SessionStart`) and which do not (`PreToolUse`, `PostToolUse`, `PreCompact`) — pick the delivery mechanism (stdout, JSON `additionalContext`, or stderr + exit 2) accordingly.
6. Update this file and `tests/` — hook and script behaviour is covered by `tests/test-*.sh`; run `bash tests/run.sh` before committing.
