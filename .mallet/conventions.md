# Framework-Specific Conventions

## Payload vs this repo's own content

`.claude/` in this repo is the **payload** — the source of truth for what gets installed to `~/.claude/` on a user's machine: `agents/`, `hooks/`, `skills/`, `templates/`, `statusline.sh`, `settings.fragment.json`, `merge-settings.sh`, `install-payload.sh`, plus the root `CLAUDE.md`.

`.mallet/` is **this repo's own state** and ships nowhere: `conventions.md` (this file), `lessons.md`, `skill-backlog.md`, `discovery-*.md`, `missions/`, `skills/`, `features/`.

Note the asymmetry: in this repo `.claude/` means "payload to be installed", but in every *other* repo `.claude/` holds only the two files Claude Code pins there (`settings.json`, `settings.local.json`). Do not carry the source-repo meaning into skill or doc text about target projects.

When adding a new skill:
- **Framework skill** (ships to every machine): `.claude/skills/<name>/`
- **Project skill** (only this repo): `.mallet/skills/<name>/`

## Payload paths in skill and doc text

Skills and docs describe the *installed* layout, so they reference `~/.claude/skills/`, `~/.claude/agents/`, `~/.claude/hooks/`, `~/.claude/templates/` — not the bare `.claude/` paths those files occupy in this repo.

Two deliberate exceptions, both in `.claude/skills/migrate/`: `detect.sh` and `migrate-repo.sh` reference `<repo>/.claude/skills/` and `<repo>/.claude/agents/` because they are detecting the *legacy* per-project payload that old installs left behind. Those must stay unprefixed.

## Ignore policy

`.mallet/` is re-included in this repo's `.gitignore` via `!.mallet/`, because feature plans are committed to `master` deliberately so they stay visible across branches. This overrides a machine-wide `.mallet/` ignore in `core.excludesFile` — in-tree `.gitignore` takes precedence over the global excludes file. Only `memory.md`, `compact-snapshot.md`, and `pipeline-state/` are ignored within it.

Do not add a `.mallet/.gitignore` here, and do not ship one from the installer: whether `.mallet/` is tracked is each user's decision. `.claude/templates/mallet-gitignore` exists as an opt-in template only.

## Tests

Hook and script behaviour is covered by portable assertion suites under `.mallet/features/<slug>/tests/`. They derive the repo root from `BASH_SOURCE`, use `mktemp -d` for scratch, and override `HOME` so the real `~/.claude/` is never read or written. Run them all before committing a change to anything under `.claude/hooks/`, `.claude/statusline.sh`, `.claude/merge-settings.sh`, `.claude/install-payload.sh`, or `.claude/skills/migrate/`:

```bash
for t in .mallet/features/*/tests/*.sh; do printf "%-24s " "$(basename $t)"; bash "$t" 2>&1 | tail -1; done
```

## Docs Parity

Any change to a skill or hook must update the corresponding section in `docs/`:
- Skill changes → `docs/skills.md`
- Hook changes → `docs/hooks.md`
- Structural changes → `docs/structure.md`
- Directive changes → `docs/directives.md`

## Session Records

Session wrap-ups are conversational only — no files are written to disk.

## Git Workflow Override

Overrides the main CLAUDE.md "Git Workflow" section for this repo only:

- Commit and push directly to `master` — do not create feature branches or PRs.
- The `b/` and `f/` branch-naming rules do not apply here.
