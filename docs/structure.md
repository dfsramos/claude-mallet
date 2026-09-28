# Project Structure

This repository is a Claude Code plugin marketplace. It hosts one plugin, `mallet`, whose source lives in `plugin/` — kept out of the repo root so `.mallet/`, `docs/`, and `tests/` never end up inside the plugin's versioned cache.

## Repository tree

Generated from the filesystem (excluding `.git`); `.mallet/features/*/tasks/` and empty `tests/` directories are collapsed for readability.

```
.
├── .claude/                           # Transition scripts only — see "Transition scripts" below
│   ├── install-payload.sh
│   ├── merge-settings.sh
│   ├── settings.fragment.json
│   └── settings.local.json            # This repo's own permissions (not shipped)
├── .claude-plugin/
│   └── marketplace.json               # Marketplace manifest: one plugin, "mallet", source "./plugin"
├── .mallet/                           # This repo's own Mallet state (not shipped)
│   ├── features/                      # Feature plans, committed directly to master
│   │   ├── harvest-skill/
│   │   ├── hooks-layer/
│   │   ├── plugin-slim-down/
│   │   └── user-level-install/
│   ├── missions/
│   ├── skills/
│   │   └── harvest/SKILL.md           # Project-only maintenance skill
│   ├── conventions.md                 # Project conventions (this file's sibling)
│   ├── discovery-2026-03-20.md
│   ├── discovery-2026-06-04.md
│   ├── lessons.md
│   └── skill-backlog.md
├── assets/
│   └── claude-mallet.jpg
├── docs/
│   ├── directives.md                  # Behavioral rules defined in the persona
│   ├── hooks.md                       # Automatic actions triggered by Claude Code events
│   ├── skills.md                      # Reusable capabilities and the skill backlog
│   └── structure.md                   # This file
├── plugin/                            # The mallet plugin — everything here ships to users
│   ├── .claude-plugin/
│   │   └── plugin.json                # Plugin manifest: name, description, author, no version
│   ├── agents/
│   │   ├── code-analyst.md            code-reviewer.md      feature-analyst.md
│   │   ├── implementer.md             plan-critic.md        scope-validator.md
│   │   └── test-runner.md
│   ├── hooks/
│   │   ├── hooks.json                 # Registers every hook below via ${CLAUDE_PLUGIN_ROOT}
│   │   ├── persona.sh                 # SessionStart: injects PERSONA.md
│   │   ├── session-start.sh           # SessionStart (startup): statusline refresh, legacy detect
│   │   ├── post-compact.sh            # SessionStart (compact): restores state after compaction
│   │   ├── typecheck.sh               # PostToolUse: opt-in linter, JSON additionalContext
│   │   ├── user-prompt-submit.sh      # UserPromptSubmit: session-watch + calibrate line
│   │   └── write-guard.sh             # PreToolUse: blocks Write on existing files
│   ├── persona/
│   │   └── PERSONA.md                 # The persona itself — not CLAUDE.md, plugins can't ship one
│   ├── skills/
│   │   ├── adr/                       create-pr/            discover/
│   │   ├── hooks-setup/               implement-feature/    next-steps/
│   │   ├── plan-feature/              preflight/            receiving-code-review/
│   │   ├── reviewing-sessions/        systematic-debugging/
│   │   ├── calibrate/                 setup/                # manual-only (disable-model-invocation)
│   │   └── migrate/                   # Legacy per-project cleanup
│   │       ├── SKILL.md               #   orchestration and user interaction
│   │       ├── detect.sh              #   find legacy installs, emit TSV
│   │       ├── migrate-repo.sh        #   migrate one repo (dry-run unless --yes)
│   │       └── mallet-gitignore       #   optional .mallet/.gitignore template
│   ├── statusline/
│   │   └── statusline.sh              # Model, effort, branch, cost, context %, rate limits, tokens
│   └── workflows/
│       └── implement-feature.js       # The spec→plan→critique→implement→test→validate→review pipeline
├── tests/
│   ├── run.sh                         # Runs every test-*.sh, exits non-zero on any failure
│   └── test-*.sh / test-14-workflow.mjs
├── .gitattributes
├── .gitignore
├── CLAUDE.md                          # This repo's own directives — not the shipped persona
├── README.md
└── install.md
```

## Transition scripts

`.claude/install-payload.sh`, `.claude/merge-settings.sh`, and `.claude/settings.fragment.json` are not payload in the old sense — they exist only so an already-installed pre-plugin `update` skill can transition a user-level `~/.claude/` install to the plugin on its next run. Their paths and CLI flags must stay stable for that reason. `install-payload.sh` now removes manifest-claimed entries, replaces `~/.claude/skills/migrate/` with a stub, and marks `~/.claude/framework.json` as transitioned; `merge-settings.sh` strips Mallet's old hook and `statusLine` registrations since the plugin registers its own. See [`README.md`](../README.md#moving-from-the-user-level-install) for the user-facing flow.

The root `CLAUDE.md` is this repo's own project instructions (not the persona users receive — that is `plugin/persona/PERSONA.md`, injected by `plugin/hooks/persona.sh`). It must keep existing because the pre-plugin `update` skills abort when the downloaded archive has none.

`.claude/settings.local.json` holds this repo's own permissions and is never part of what ships.

## What a target project looks like

Installing the plugin writes nothing into any repository. A project only gains a `.mallet/` directory, and only once Mallet has something project-specific to store there:

```
<any-project>/
├── CLAUDE.md                          # The project's own, if any — never touched
├── .claude/
│   └── settings.local.json            # User permissions — Mallet never touches this
└── .mallet/                           # Mallet's project state, all optional
    ├── conventions.md                 # Project conventions, read at session start
    ├── typecheck.enabled              # Marker: opt in to the typecheck hook
    ├── skill-backlog.md               # Candidate skills, reviewed at wrap-up
    ├── discovery-*.md                 # Discovery reports
    ├── missions/                      # Active and archived mission files
    ├── overrides/<skill-name>.md      # Per-skill amendments to base skills
    ├── skills/                        # Project-specific skills
    └── features/<slug>/               # Feature plans
```

Project-specific facts, corrections, and preferences that used to live in `.mallet/memory.md` and `.mallet/lessons.md` are now Claude Code's own auto memory — there is no Mallet-owned memory file to inject or maintain. `/mallet:setup` offers to fold any leftover legacy files into auto memory the first time it runs in a project that still has them.

Whether `.mallet/` is tracked by git is the user's own choice. Mallet ships no `.gitignore` into it and never edits a repo's own `.gitignore` or excludes file without an explicit answer during `migrate`.

## Key paths

| Path | Purpose |
|---|---|
| `plugin/persona/PERSONA.md` | The persona, injected by `plugin/hooks/persona.sh` every session |
| `plugin/hooks/hooks.json` | Registers every hook script via `${CLAUDE_PLUGIN_ROOT}` |
| `plugin/skills/` | Skills, namespaced `mallet:<name>` (`/mallet:<name>`) at runtime |
| `plugin/agents/` | Sub-agent persona definitions, namespaced `mallet:<name>` |
| `plugin/workflows/implement-feature.js` | The review pipeline, launched by the `implement-feature` skill |
| `plugin/statusline/statusline.sh` | Copied to `${CLAUDE_PLUGIN_DATA}` by `session-start.sh`; registered by `/mallet:setup` |
| `${CLAUDE_PLUGIN_ROOT}` | Resolves to the installed plugin version at runtime — always used for script paths |
| `${CLAUDE_PLUGIN_DATA}` | Persistent per-plugin data directory, survives plugin updates |
| `${CLAUDE_SKILL_DIR}` | The currently-running skill's own directory — used for template/script references |
| `<project>/.mallet/` | That project's Mallet state |
| `<project>/.mallet/conventions.md` | Project conventions layered on top of the persona |
| `.claude/install-payload.sh`, `.claude/merge-settings.sh` | *(this repo)* transition-only, see above |
| `.mallet/features/` | *(this repo)* feature plans, committed directly to master |
| `tests/run.sh` | *(this repo)* runs every suite in `tests/`, exits non-zero on failure |

On-demand files are documented in the directives and skills that own them — see [`directives.md`](directives.md) and [`skills.md`](skills.md).
