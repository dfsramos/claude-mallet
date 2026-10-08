# Framework-Specific Conventions

## Payload vs this repo's own content

`plugin/` in this repo is the **payload** — the source of truth for what ships in the `mallet` plugin: `agents/`, `hooks/`, `persona/`, `skills/`, `statusline/`, `workflows/`, plus `plugin/.claude-plugin/plugin.json`. The marketplace manifest, `.claude-plugin/marketplace.json`, points at it as `./plugin`.

`.claude/` in this repo now holds only this repo's own `settings.local.json` (not shipped) plus three files kept solely so an already-installed pre-plugin `update` skill can transition a user-level install to the plugin: `install-payload.sh`, `merge-settings.sh`, `settings.fragment.json`. Their paths and CLI flags must stay stable for that reason — see `docs/structure.md` — but they are not otherwise touched by a fresh install.

`.mallet/` is **this repo's own state** and ships nowhere: `conventions.md` (this file), `skill-backlog.md`, `discovery-*.md`, `missions/`, `skills/`, `features/`.

When adding a new skill:
- **Plugin skill** (ships with every install): `plugin/skills/<name>/`
- **Project skill** (only this repo): `.mallet/skills/<name>/`

## Payload paths in skill and doc text

Skills and docs describe the *installed* plugin layout, so they reference `${CLAUDE_PLUGIN_ROOT}` (the plugin's own root at runtime), `${CLAUDE_PLUGIN_DATA}` (persistent per-plugin data), and `${CLAUDE_SKILL_DIR}` (the running skill's own directory) — not the bare `plugin/` path those files occupy in this repo. Skill and agent references use the namespaced runtime form, `/mallet:<name>` / `mallet:<name>`, not the bare directory name.

One deliberate exception, in `plugin/skills/migrate/`: `detect.sh` and `migrate-repo.sh` reference `<repo>/.claude/skills/` and `<repo>/.claude/agents/` because they are detecting the *legacy* per-project payload that old installs left behind in target repos. Those must stay unprefixed.

## Ignore policy

`.mallet/` is re-included in this repo's `.gitignore` via `!.mallet/`, because feature plans are committed to `master` deliberately so they stay visible across branches. This overrides a machine-wide `.mallet/` ignore in `core.excludesFile` — in-tree `.gitignore` takes precedence over the global excludes file. Only `memory.md`, `compact-snapshot.md`, and `pipeline-state/` are ignored within it.

Do not add a `.mallet/.gitignore` here, and do not ship one from the plugin: whether `.mallet/` is tracked is each user's decision. `plugin/skills/migrate/mallet-gitignore` exists as an opt-in template only.

## Tests

Hook, script, and workflow behaviour is covered by `tests/*.sh` (plus `tests/test-14-workflow.mjs` for the Workflow script). They derive the repo root from `BASH_SOURCE`, use `mktemp -d` for scratch, and override `HOME` so the real `~/.claude/` is never read or written. Run the whole suite before committing a change to anything under `plugin/hooks/`, `plugin/statusline/`, `.claude/` (the transition scripts), `plugin/skills/migrate/`, or `plugin/workflows/`:

```bash
bash tests/run.sh
```

`tests/run.sh` prints one line per suite and exits non-zero if any failed.

Tests cover executable code: hooks, the statusline, scripts that edit user files, and plugin structure. Skill prose is not shell-tested. Some suites exist only for transitional code and go when it does: `test-01-merge.sh` and `test-17-transition.sh` with the `.claude/` transition scripts, and `test-05-migrate.sh` and `test-07-legacy.sh` with the `migrate` skill.

## Hook Authoring

Plugin hooks reach the model only through the channels each event supports: plain stdout on SessionStart and UserPromptSubmit; JSON `hookSpecificOutput.additionalContext` on PreToolUse and PostToolUse; stderr with exit 2 to block. Anything else goes to the debug log. Inject dynamic content this way, into the message stream, rather than by changing system-prompt material (the persona, CLAUDE.md) mid-session — that invalidates the prompt cache. Keep any single hook's output under 10,000 characters, or Claude receives only a file path and a preview.

Hook scripts must run on macOS as well as Linux, and the tests only run on Linux, so write to the common subset: bash 3.2 (no `mapfile`/`readarray`, no associative arrays, no `local -n` namerefs), BSD `sed` (no `\n` in a replacement — split with `tr`), and `%.Nf` formatting only under `LC_ALL=C`. `tests/test-20-portability.sh` checks the bash constructs and the `%.Nf` rule statically; to confirm a statusline or hook change on real bash 3.2, run it in the `bash:3.2` Docker image. A hook that parses command strings strips quoted text from the whole command before matching, and its tests include multi-line and heredoc inputs.

### Mods

Claude Code mods (v2.1.287+, October 2026) are JavaScript event handlers that run inside Claude Code as part of a plugin; see https://code.claude.com/docs/en/plugins/mods/overview. Plugin shell hooks stay the baseline for anything Mallet must always do: managed `allowManagedModsOnly` blocks installed mods while plugin shell hooks keep running, mods do not load in the Desktop app's WSL sessions, and they need a recent Claude Code. Reach for a mod only for what a hook cannot do at all — drawing interface, or reading session state such as `$.session.usage()` (context percent, rate limits, cost) directly — and keep a hook fallback for the same behaviour.

First candidate when revisited: an optional mod for the `[calibrate]` line and session-watch, reading model and context usage from `$.session` instead of the statusline's temp state file, with `user-prompt-submit.sh` as the fallback. Check the type declarations for where the effort level is readable outside `turn.step` before building it.

## Docs Parity

Any change to a skill or hook under `plugin/` must update the corresponding section in `docs/`:
- Skill changes → `docs/skills.md`
- Hook changes → `docs/hooks.md`
- Structural changes → `docs/structure.md`
- Directive changes (`plugin/persona/PERSONA.md`) → `docs/directives.md`

## Session Records

Session wrap-ups are conversational only — no session summary or retrospective file is written to disk. Mission files in `.mallet/missions/` are not session records: `reviewing-sessions` still writes and archives them.

## Git Workflow Override

Overrides the main CLAUDE.md "Git Workflow" section for this repo only:

- Commit and push directly to `master` — do not create feature branches or PRs.
- The `b/` and `f/` branch-naming rules do not apply here.
