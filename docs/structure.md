# Project Structure

This repository is a Claude Code plugin marketplace. It hosts one plugin, `mallet`, whose source lives in `plugin/` — kept out of the repo root so `.mallet/`, `docs/`, and `tests/` never end up inside the plugin's versioned cache.

## Repository tree

Generated from the filesystem (excluding `.git`); `.mallet/features/*/tasks/` directories are collapsed for readability.

```
.
├── .claude/                           # Transition scripts, this repo's rules and maintenance skills (not shipped)
│   ├── install-payload.sh             # Transition only — see "Transition scripts" below
│   ├── merge-settings.sh
│   ├── settings.fragment.json
│   ├── settings.local.json            # This repo's own permissions
│   ├── rules/
│   │   └── hooks.md                   # Path-scoped rules for hook, statusline and test code
│   └── skills/
│       ├── harvest/SKILL.md           # Project-only maintenance skill
│       └── self-assessment/SKILL.md   # Project-only: critical review of Mallet, fixed in groups
├── .claude-plugin/
│   └── marketplace.json               # Marketplace manifest: one plugin, "mallet", source "./plugin"
├── .mallet/                           # This repo's own Mallet state (not shipped)
│   ├── features/                      # Feature plans, committed directly to master
│   │   ├── harvest-skill/
│   │   ├── hooks-layer/
│   │   ├── plugin-slim-down/
│   │   └── user-level-install/
│   ├── missions/                      # Leftover of the mission mechanism retired 2026-10-20; no longer read
│   ├── discovery-2026-03-20.md
│   ├── discovery-2026-06-04.md
│   ├── eval-2026-10.md                # Persona eval write-up (full vs trimmed persona vs none)
│   ├── eval-2026-10-19-fable.json     # Eval results, full persona
│   ├── eval-2026-10-19-fable-trimmed.json
│   └── relevance-2026-10-19.md        # The assessment behind the 2026-10-20 prune
├── assets/
│   └── claude-mallet.jpg
├── docs/
│   ├── directives.md                  # Behavioral rules defined in the persona
│   ├── hooks.md                       # Automatic actions triggered by Claude Code events
│   ├── skills.md                      # Reusable capabilities
│   └── structure.md                   # This file
├── plugin/                            # The mallet plugin — everything here ships to users
│   ├── .claude-plugin/
│   │   └── plugin.json                # Plugin manifest: name, description, author, no version
│   ├── agents/
│   │   ├── code-reviewer.md           scope-validator.md            # standalone reviewers of a change set
│   │   ├── council-contrarian.md      council-executor.md
│   │   └── council-expansionist.md    council-first-principles.md   # the council skill's advisors
│   ├── evals/                         # `claude plugin eval` suite: one directory per case (prompt.md, graders/)
│   ├── hooks/
│   │   ├── hooks.json                 # Registers the three hooks below via ${CLAUDE_PLUGIN_ROOT}
│   │   ├── persona.sh                 # SessionStart: injects PERSONA.md
│   │   ├── session-start.sh           # SessionStart (startup|resume|clear|compact): statusline, legacy detect, Git conventions check
│   │   └── post-compact.sh            # SessionStart (compact): git state after compaction
│   ├── persona/
│   │   └── PERSONA.md                 # The persona itself — not CLAUDE.md, plugins can't ship one
│   ├── rules/
│   │   └── git.md                     # Default Git conventions; session-start.sh offers them to a repo that states none
│   ├── skills/
│   │   ├── adr/                       council/              create-pr/            next-steps/
│   │   ├── plan-feature/              receiving-code-review/ reviewing-sessions/  systematic-debugging/
│   │   ├── write-task/
│   │   ├── setup/                     # manual-only (disable-model-invocation)
│   │   └── migrate/                   # Legacy per-project cleanup
│   │       ├── SKILL.md               #   orchestration and user interaction
│   │       ├── detect.sh              #   find legacy installs, emit TSV
│   │       ├── migrate-repo.sh        #   migrate one repo (dry-run unless --yes)
│   │       └── mallet-gitignore       #   optional .mallet/.gitignore template
│   └── statusline/
│       └── statusline.sh              # Model, effort, branch, cost, context tokens, rate limits
├── tests/
│   ├── run.sh                         # Runs every test-*.sh, exits non-zero on any failure
│   └── test-*.sh
├── .gitattributes
├── .gitignore
├── CHANGELOG.md                       # What each update changes for users, dated (no version field)
├── CLAUDE.md                          # This repo's own conventions — not the shipped persona
├── README.md
└── install.md
```

## Transition scripts

`.claude/install-payload.sh`, `.claude/merge-settings.sh`, and `.claude/settings.fragment.json` are not payload in the old sense — they exist only so an already-installed pre-plugin `update` skill can transition a user-level `~/.claude/` install to the plugin on its next run. Their paths and CLI flags must stay stable for that reason. `install-payload.sh` now removes manifest-claimed entries, replaces `~/.claude/skills/migrate/` with a stub, and marks `~/.claude/framework.json` as transitioned; `merge-settings.sh` strips Mallet's old hook and `statusLine` registrations since the plugin registers its own. See [`README.md`](../README.md#moving-from-the-user-level-install) for the user-facing flow.

**Retirement.** The transition code goes once every known user has moved to the plugin: each confirms that `~/.claude/framework.json` shows `"transitioned": "plugin"` (or no longer exists) and that `/mallet:migrate` finds no per-project install in their repos. It is then removed in one change: `.claude/install-payload.sh`, `.claude/merge-settings.sh`, `.claude/settings.fragment.json`, the `migrate` skill, the legacy check in `session-start.sh`, `setup` steps 3 and 4, tests `test-01`, `test-05`, `test-07`, and `test-17`, and the requirement below that the root `CLAUDE.md` keep existing.

The root `CLAUDE.md` is this repo's own project instructions (not the persona users receive — that is `plugin/persona/PERSONA.md`, injected by `plugin/hooks/persona.sh`). It must keep existing because the pre-plugin `update` skills abort when the downloaded archive has none.

`.claude/settings.local.json` holds this repo's own permissions and is never part of what ships.

## What a target project looks like

Installing the plugin writes nothing into any repository. The one file Mallet offers to add is `.claude/rules/git.md`, and only when the user agrees; otherwise a project only gains a `.mallet/` directory, and only once Mallet has something project-specific to store there:

```
<any-project>/
├── CLAUDE.md                          # The project's own, if any — never touched
├── .claude/
│   ├── rules/git.md                   # Mallet's default Git conventions, only if the user accepted the offer
│   ├── skills/                        # The project's own skills, loaded by Claude Code; plan-feature scaffolds knowledge skills here
│   └── settings.local.json            # User permissions — Mallet never touches this
└── .mallet/                           # Mallet's project state, all optional
    ├── discovery-*.md                 # Reports from the removed discover skill, kept for reference
    └── features/<slug>/               # Feature plans
```

Leftovers from earlier Mallet versions may also sit in `.mallet/`; since 2026-10-20 nothing reads or writes them: `conventions.md` (move its content to `CLAUDE.md` or `.claude/rules/`), `overrides/` (a skill amendment is now `.claude/rules/<skill>.md`), `skills/` (move to `.claude/skills/`), `missions/` (`reviewing-sessions` offers to fold `active.md` into auto memory and archive or delete it), `skill-backlog.md` (`reviewing-sessions` drains and deletes it), and the `typecheck.enabled` and `command-guard.enabled` markers (inert; delete them).

Project-specific facts, corrections, and preferences that used to live in `.mallet/memory.md` and `.mallet/lessons.md` are now Claude Code's own auto memory — there is no Mallet-owned memory file to inject or maintain. `/mallet:setup` offers to fold any leftover legacy files into auto memory the first time it runs in a project that still has them.

Whether `.mallet/` is tracked by git is the user's own choice. Mallet ships no `.gitignore` into it and never edits a repo's own `.gitignore` or excludes file without an explicit answer during `migrate`.

## Key paths

| Path | Purpose |
|---|---|
| `plugin/persona/PERSONA.md` | The persona, injected by `plugin/hooks/persona.sh` every session |
| `plugin/rules/git.md` | Default Git conventions; `session-start.sh` prints them in a repository that states none and offers them as `.claude/rules/git.md` |
| `plugin/hooks/hooks.json` | Registers every hook script via `${CLAUDE_PLUGIN_ROOT}` |
| `plugin/skills/` | Skills, namespaced `mallet:<name>` (`/mallet:<name>`) at runtime |
| `plugin/agents/` | Sub-agent persona definitions, namespaced `mallet:<name>` |
| `plugin/evals/` | The persona eval suite for `claude plugin eval`; inert unless run |
| `plugin/statusline/statusline.sh` | Copied to `${CLAUDE_PLUGIN_DATA}` by `session-start.sh`; registered by `/mallet:setup` |
| `${CLAUDE_PLUGIN_ROOT}` | Resolves to the installed plugin version at runtime — always used for script paths |
| `${CLAUDE_PLUGIN_DATA}` | Persistent per-plugin data directory, survives plugin updates |
| `${CLAUDE_SKILL_DIR}` | The currently-running skill's own directory — used for template/script references |
| `<project>/.mallet/` | That project's Mallet state |
| `<project>/.claude/rules/` | The project's own rules, loaded by Claude Code; where Mallet's Git conventions land if accepted, and where amendments to a Mallet skill go |
| `<project>/.claude/skills/` | The project's own skills, loaded by Claude Code |
| `.claude/install-payload.sh`, `.claude/merge-settings.sh` | *(this repo)* transition-only, see above |
| `.claude/rules/hooks.md`, `.claude/skills/` | *(this repo)* conventions for hook and test code, and the maintenance skills `harvest` and `self-assessment` |
| `.mallet/features/` | *(this repo)* feature plans, committed directly to master |
| `tests/run.sh` | *(this repo)* runs every suite in `tests/`, exits non-zero on failure |

On-demand files are documented in the directives and skills that own them — see [`directives.md`](directives.md) and [`skills.md`](skills.md).
