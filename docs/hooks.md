# Hooks

Hooks are shell scripts that run automatically in response to Claude Code events. They live at `plugin/hooks/` and ship with the plugin — every user runs the same scripts, registered in `plugin/hooks/hooks.json` via `${CLAUDE_PLUGIN_ROOT}`, which resolves to the installed plugin version at runtime.

Each hook locates its *data* through `$CLAUDE_PROJECT_DIR`, so the one global script reads whichever project's `.mallet/` state is current.

## A fact that shapes every hook here

**For `PreToolUse`, `PostToolUse`, and `PreCompact`, plain stdout on exit 0 is written only to the debug log — it never reaches the model.** Only `UserPromptSubmit` and `SessionStart` stdout is added to context. This is why `typecheck-stop.sh` (Stop) returns its findings as JSON `additionalContext` instead of printing them, why `write-guard.sh` and `command-guard.sh` (PreToolUse) answer with a JSON `permissionDecision` (`deny` reasons go to the model, `ask` reasons to the user's permission prompt), and why `write-guard.sh` blocks Write by writing to stderr and exiting `2` — a blocking exit's stderr is fed back to the model as the reason, regardless of event type.

## Registration

All eight scripts are registered in one file, `plugin/hooks/hooks.json`:

| Hook | Event | Matcher |
|---|---|---|
| `persona.sh` | SessionStart | `startup\|resume\|clear\|compact` |
| `session-start.sh` | SessionStart | `startup\|clear\|compact` |
| `post-compact.sh` | SessionStart | `compact` |
| `user-prompt-submit.sh` | UserPromptSubmit | *(none — every prompt)* |
| `write-guard.sh` | PreToolUse | `Edit\|Write` |
| `command-guard.sh` | PreToolUse | `Bash` |
| `typecheck.sh` | PostToolUse | `Edit\|Write` |
| `typecheck-stop.sh` | Stop | *(none)* |

There is no separate opt-in registration tier at the settings level any more — the plugin registers everything globally. `typecheck.sh`, `typecheck-stop.sh`, and `command-guard.sh` are opt-in in effect only, gated on a per-project marker file (see below), because a per-project `settings.json` registration would need a stable script path, which a versioned plugin cache does not provide.

## Persona Hook

**File:** `plugin/hooks/persona.sh`
**Trigger:** `SessionStart`, matcher `startup|resume|clear|compact`

Injects the Mallet persona (`plugin/persona/PERSONA.md`) as session context. This is the only way the plugin delivers its directives — **plugins cannot ship a `CLAUDE.md`** — and it fires on `clear` and `compact` too, since both drop earlier context that would otherwise carry the persona with it.

Hook stdout over 10,000 characters is replaced by a file path and a 2,000-character preview instead of being injected whole, so `PERSONA.md` must stay under that. It is currently well under (`tests/test-15-plugin.sh` enforces under 9,800 characters as a safety margin). If `${CLAUDE_PLUGIN_ROOT}` is unset (e.g. run standalone), it falls back to resolving the script's own directory.

## Session Start Hook

**File:** `plugin/hooks/session-start.sh`
**Trigger:** `SessionStart`, matcher `startup|clear|compact`; the hook reads `source` from its input (with `sed`, so it works without `jq`) to decide which jobs run

Four independent jobs, all cheap and network-free:

1. **Statusline refresh** (`startup`). A `statusLine` command cannot reference `${CLAUDE_PLUGIN_ROOT}`, which changes with every plugin version, so `/mallet:setup` points `statusLine` at a copy in `${CLAUDE_PLUGIN_DATA}` instead. This hook keeps that copy current by comparing it against `${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh` on every startup and overwriting it (via a temp file + `mv`) when they differ, so a plugin update reaches the statusline without a manual step.
2. **Legacy per-project install detection** (`startup`). If the current project still carries a per-project Mallet payload — `.claude/framework.json`, or both `.claude/skills/update/SKILL.md` and `.claude/agents/_contract.md` — prints a notice offering the `migrate` skill. Two exemptions prevent it nagging forever: the install's own project root (identified by `.claude/settings.fragment.json` / `.claude/install-payload.sh`, which only this source repo has), and any project where `.mallet/.migration-declined` exists.
3. **Project skills** (all three sources). Claude Code discovers skills only in `.claude/skills/`, so the persona's "treat `.mallet/skills/` as an additional skills directory" needs help: the hook lists each `.mallet/skills/*/SKILL.md` by name with its `description` (first 300 characters, at most 25 skills, keeping the output under the 10,000-character hook limit) and tells Claude to read a skill's file when its trigger applies. It runs on `clear` and `compact` too, because both drop the earlier listing from context.
4. **Open mission** (`startup`, `clear`). If `.mallet/missions/active.md` exists, and has at least one unchecked `- [ ]` task, prints its `# Mission:` title and that count, and tells Claude to surface them and ask whether to resume — backing the persona's Continuity directive with a signal instead of relying on Claude to look unprompted. After `compact`, `post-compact.sh` restores the mission itself, so this one stays quiet.

There is no update check here any more — updates arrive through the plugin system itself, so the GitHub-polling logic and its 24-hour cache are gone.

## Post-Compact Hook

**File:** `plugin/hooks/post-compact.sh`
**Trigger:** `SessionStart`, matcher `compact`

Restores working state immediately after a compaction, in the same session: current git branch, uncommitted changes (`git status --short`, up to 15 lines), the last 5 commits, the list of mission files present, and the contents of `.mallet/missions/active.md` if one exists, capped at 7,000 bytes with a truncation notice so the whole output stays under the 10,000-character limit for hook output.

This replaces the old `pre-compact.sh` for two reasons: `PreCompact` stdout never reaches the model (see the fact above), so its context injection was silently doing nothing; and its snapshot file (`.mallet/compact-snapshot.md`) could leak into a later, unrelated session if that session started before the file was consumed. Emitting fresh state from a `SessionStart` hook instead means there is no file to persist and nothing to leak.

## UserPromptSubmit Hook

**File:** `plugin/hooks/user-prompt-submit.sh`
**Trigger:** Every user message submitted to Claude

Two independent checks:

**Session-watch.** Suggests compaction as the context window fills. It reads `context_window.used_percentage` from the per-session state file `statusline.sh` writes (below) and injects a `[session-watch]` reminder at 60% and a stronger one at each further 15% (75%, 90%). A sibling `mallet-watch-<session_id>.last` file records the last band warned, so each band warns once; dropping below 60% (after `/compact`) re-arms the first warning. Context usage replaced a prompt count because prompts are a poor proxy for window pressure — one prompt can pull in a large file or log.

Without a Mallet statusline there is no usage figure, so it falls back to counting human-typed prompts — transcripts mark them with `origin.kind == "human"`; tool results, agent hand-backs, and skill expansions are also stored as role `user` and are excluded, since counting them previously inflated the total roughly 7x. At 50 prompts it injects a soft reminder; at 80 and every 20 after, a stronger warning.

**Calibrate.** Injects a `[calibrate] active model: X; effort: Y` line when either value changes since the last prompt. Neither value is visible to this hook directly, so it reads them from a per-session state file (`${TMPDIR:-/tmp}/mallet-calibrate-<session_id>.json`) that `statusline.sh` writes on every render from the session JSON's `model.id`, `effort.level`, and `context_window.used_percentage`. `effort.level` tracks mid-session `/effort` changes and is absent when the active model has no effort parameter. If no such state file exists (no Mallet statusline registered), it falls back to `effortLevel` in the most specific `settings.local.json`/`settings.json` it can find, and says so, since that fallback cannot see live `/effort` changes. The line is written once per change, tracked via a sibling `.last` file, so it costs nothing on unchanged turns.

## Write Guard Hook

**File:** `plugin/hooks/write-guard.sh`
**Trigger:** `PreToolUse`, matcher `Edit|Write`

Blocks `Write` calls on files that already exist — the persona requires `Edit` for existing files, since `Edit` sends only the changed lines while `Write` re-sends the whole file. Reads `tool_input.file_path`; if it points to an existing file, writes the block reason to **stderr** and exits `2`. Exit 2 is what feeds the message back to the model as the block reason — plain stdout would not, per the fact above. New files (`Write` creating something that doesn't exist) pass through with exit 0.

It also asks before `Edit` changes an existing linter or type-checker config — ESLint, Prettier, Biome, Stylelint, `tsconfig*.json`/`jsconfig.json`, Ruff, mypy, Flake8, Pylint, PHPStan, Psalm, PHP-CS-Fixer, golangci-lint — returning `permissionDecision: "ask"`, whose reason appears in the user's permission prompt. A failing check should be fixed in the code, not loosened in its config; when the config change is intended, the user allows it. Creating a new config file is not asked about. A hook `ask` forces the prompt even in auto mode.

## Typecheck Hooks

**Files:** `plugin/hooks/typecheck.sh`, `plugin/hooks/typecheck-stop.sh`
**Trigger:** `PostToolUse`, matcher `Edit|Write` (record); `Stop` (check)
**Activation:** opt-in per project via a marker file, not a settings registration

The plugin registers both hooks for every project, but they do nothing unless `.mallet/typecheck.enabled` exists at the project root (created by the `hooks-setup` skill). A per-project `settings.json` hook registration would need to reference a stable script path, and the plugin cache path changes with every version — the marker file is what makes the opt-in per-project instead.

`typecheck.sh` only records each edited `.ts`, `.tsx`, or `.php` file in `${TMPDIR:-/tmp}/mallet-typecheck-<session_id>.list`. When Claude finishes the turn, `typecheck-stop.sh` checks them once: the project's own `tsc --noEmit` (if `tsconfig.json` exists and `node_modules/.bin/tsc` is found in the project or a parent directory, so a monorepo package finds a hoisted install; never `npx tsc`, which without a local install fetches the unrelated `tsc` package; Yarn PnP projects have no `node_modules/.bin` and are skipped) filtered to errors in the recorded files, and `vendor/bin/phpstan analyse --error-format=raw <files>` (if the binary exists), each capped to 20 lines. The Stop registration sets a 120-second `timeout`, so a slow full-project `tsc` cannot hold the turn open for the 600-second default. The list of edited files is cleared only after the checks finish, so a check the timeout kills runs again at the next turn's end. Checking once per turn replaced a full-project check after every edit, which repeated the same work and reported half-finished multi-edit states as errors. Filtering to the turn's files keeps pre-existing errors elsewhere from stopping every turn.

Errors come back as Stop `additionalContext` — non-error feedback that continues the turn so Claude fixes them. When `stop_hook_active` is set (the turn is already continuing because of a Stop hook), it lets the turn end and keeps the list, so the next turn's check still covers those files without any risk of a loop.

## Command Guard Hook

**File:** `plugin/hooks/command-guard.sh`
**Trigger:** `PreToolUse`, matcher `Bash`
**Activation:** opt-in per project via `.mallet/command-guard.enabled`

A narrow safety net for commands that bypass checks or destroy work, applied to each simple command in a `;`/`&&`/`||`/`|` chain:

| Decision | Commands |
|---|---|
| `deny` (reason to Claude) | `--no-verify`, `git commit -n`, `core.hooksPath` overrides; force-pushing the default branch (named, or pushed from while checked out) |
| `ask` (reason to the user) | other force-pushes, `git reset --hard`, `git clean -f…`, `git checkout/restore .`, `git branch -D`, `git stash drop/clear`, `rm` with `-r` and `-f` (unless every target is a build directory such as `node_modules` or `dist`), `DROP`/`TRUNCATE`/`DELETE FROM`/`ALTER TABLE … DROP` passed to a SQL client, `kubectl delete`, `terraform destroy` |

Quoted strings are removed from the whole command before it is split, so a commit message — single-line, multi-line, or heredoc-fed — cannot trigger a git or `rm` rule. Destructive SQL needs a database client (`psql`, `mysql`, `sqlcmd`, …) running as a command, while the statement itself is matched anywhere, so `-c` arguments, heredocs, and piped input are covered. Git's global options are skipped to find the real subcommand, leading environment assignments and `sudo` are ignored, redirections such as `2>&1` are not mistaken for separators, and a quoted `core.hooksPath` override is checked against the raw command. Three forms are recovered before the quote strip would hide them: a shell's `-c` script (`bash -c "git push -f"`, also `sh`, `zsh`, a path such as `/bin/bash`, and options such as `-lc`, `--norc`, or `-o pipefail`) is split out as its own command; a quoted single word that is not an option (`"main"`) loses its quotes, so a quoted branch name still counts, while `-m "--no-verify"` stays a message; and a path-qualified command (`/usr/bin/git`) is reduced to its name. A quoted word containing the other quote character (`"don't"`) stays quoted, because a stray apostrophe would pair with a later one and hide the commands between them. Known gaps: a quoted option (`git push "--force"`) is not seen, and a `-c` script containing escaped quotes is cut at the first one. Pattern matching on command strings is never complete — variables, aliases, `eval`, and scripts that run these commands internally defeat it — so the hook asks rather than judges, and complements permission rules rather than replacing them. It is opt-in because it adds permission prompts, and some workflows run these commands routinely.

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
