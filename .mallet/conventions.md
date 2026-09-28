# Framework-Specific Conventions

## Payload vs this repo's own content

`plugin/` in this repo is the **payload** — the source of truth for what ships in the `mallet` plugin: `agents/`, `hooks/`, `persona/`, `skills/`, `statusline/`, `workflows/`, plus `plugin/.claude-plugin/plugin.json`. The marketplace manifest, `.claude-plugin/marketplace.json`, points at it as `./plugin`.

`.claude/` in this repo now holds only this repo's own `settings.local.json` (not shipped) plus three files kept solely so an already-installed pre-plugin `update` skill can transition a user-level install to the plugin: `install-payload.sh`, `merge-settings.sh`, `settings.fragment.json`. Their paths and CLI flags must stay stable for that reason — see `docs/structure.md` — but they are not otherwise touched by a fresh install.

`.mallet/` is **this repo's own state** and ships nowhere: `conventions.md` (this file), `lessons.md`, `skill-backlog.md`, `discovery-*.md`, `missions/`, `skills/`, `features/`.

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

## Hook Authoring

Plugin hooks reach the model only through the channels each event supports: plain stdout on SessionStart and UserPromptSubmit; JSON `hookSpecificOutput.additionalContext` on PreToolUse and PostToolUse; stderr with exit 2 to block. Anything else goes to the debug log. Inject dynamic content this way, into the message stream, rather than by changing system-prompt material (the persona, CLAUDE.md) mid-session — that invalidates the prompt cache. Keep any single hook's output under 10,000 characters, or Claude receives only a file path and a preview.

## Docs Parity

Any change to a skill or hook under `plugin/` must update the corresponding section in `docs/`:
- Skill changes → `docs/skills.md`
- Hook changes → `docs/hooks.md`
- Structural changes → `docs/structure.md`
- Directive changes (`plugin/persona/PERSONA.md`) → `docs/directives.md`

## Session Records

Session wrap-ups are conversational only — no files are written to disk.

## Git Workflow Override

Overrides the main CLAUDE.md "Git Workflow" section for this repo only:

- Commit and push directly to `master` — do not create feature branches or PRs.
- The `b/` and `f/` branch-naming rules do not apply here.
