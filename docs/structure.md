# Project Structure

Three trees matter: this source repo, the machine-wide install it produces, and what a target project looks like.

## 1. This repo (source of truth)

```
.
├── CLAUDE.md                          # Core directives — payload, becomes ~/.claude/CLAUDE.md
├── README.md                          # Project overview and installation instructions
├── install.md                         # Remote installation instructions (used by install flow)
├── .claude/
│   ├── settings.fragment.json         # Hook + statusline registrations, jq-merged at install
│   ├── merge-settings.sh              # Merges the fragment into ~/.claude/settings.json
│   ├── install-payload.sh             # Per-entry payload install + manifest reconciliation
│   ├── statusline.sh                  # Statusline renderer
│   ├── hooks/
│   │   ├── session-start.sh           # Memory/lessons/conventions, snapshot restore, update check, legacy detect
│   │   ├── user-prompt-submit.sh      # Complexity scoring and turn tracking
│   │   ├── write-guard.sh             # Blocks Write on existing files (default)
│   │   ├── pre-compact.sh             # Captures state before compaction (default)
│   │   ├── typecheck.sh               # PostToolUse linter for TS/PHP (opt-in)
│   │   ├── push-confirm.sh            # PreToolUse warning before git push (opt-in)
│   │   └── explore-redirect.sh        # Steers broad searches toward richer sources (opt-in)
│   ├── agents/
│   │   ├── _contract.md               # Shared agent contract (capabilities, tone, tool access)
│   │   ├── code-analyst.md            code-reviewer.md      feature-analyst.md
│   │   ├── implementer.md             plan-critic.md        scope-validator.md
│   │   └── test-runner.md
│   ├── skills/
│   │   ├── adr/                       create-pr/            discover/
│   │   ├── dispatching-parallel-agents/                     hooks-setup/
│   │   ├── implement-feature/         plan-feature/         preflight/
│   │   ├── receiving-code-review/     reviewing-sessions/   systematic-debugging/
│   │   ├── task-calibrate/            update/
│   │   └── migrate/                   # Legacy per-project cleanup
│   │       ├── SKILL.md               #   orchestration and user interaction
│   │       ├── detect.sh              #   find legacy installs, emit TSV
│   │       └── migrate-repo.sh        #   migrate one repo (dry-run unless --yes)
│   ├── templates/
│   │   ├── knowledge-skill/SKILL.md   # Template for domain knowledge skills
│   │   └── mallet-gitignore           # OPTIONAL .mallet/.gitignore — never auto-installed
│   └── settings.local.json            # This repo's own permissions (not payload)
├── .mallet/                           # This repo's own Mallet state (not payload)
│   ├── conventions.md                 # Project conventions
│   ├── lessons.md                     # Recorded after user corrections
│   ├── skill-backlog.md               # Ideas for future skills
│   ├── discovery-*.md                 # Dated discovery reports
│   ├── missions/                      # Active and archived mission files
│   ├── skills/harvest/SKILL.md        # Maintenance skills for this repo
│   └── features/<slug>/               # Feature plans committed directly to master
│       ├── plan.md  state.md
│       ├── tasks/
│       └── tests/                     # Portable assertion suites for the feature
└── docs/
    ├── structure.md                   # This file
    ├── directives.md                  # Behavioral rules defined in CLAUDE.md
    ├── hooks.md                       # Automatic actions triggered by Claude Code events
    └── skills.md                      # Reusable capabilities and the skill backlog
```

## 2. The machine-wide install

Installing writes only here. No repository is modified.

```
~/.claude/
├── CLAUDE.md                          # Replaced (existing file backed up, with confirmation)
├── settings.json                      # MERGED — never overwritten
├── framework.json                     # Version + manifest of what Mallet owns
├── statusline.sh                      # Replaced
├── skills/                            # Replaced PER ENTRY — user-authored skills survive
├── agents/                            # Replaced per entry
├── templates/                         # Replaced per entry
├── hooks/                             # Replaced per entry
├── .mallet-update-check               # 24h update-check cache
└── mallet-*-backup-*.tar.gz           # Pre-install, pre-update, and migration backups
```

Never removed wholesale: `skills/`, `agents/`, `templates/`, `hooks/`. They may hold entries the user wrote. Only individual payload entries are replaced, and `framework.json.manifest` records which ones are Mallet's so a later release can remove what it drops without touching anything else.

## 3. A target project

```
<any-project>/
├── CLAUDE.md                          # The project's own, if any — NEVER touched
└── .claude/
│   ├── settings.json                  # Opt-in hook registrations only (optional)
│   └── settings.local.json            # User permissions — never touched
└── .mallet/                           # Mallet's project state, all optional
    ├── conventions.md                 # Project conventions (was .claude/project/CLAUDE.md)
    ├── memory.md                      # Project memory
    ├── lessons.md                     # Recorded corrections
    ├── skill-backlog.md               # Candidate skills
    ├── discovery-*.md                 # Discovery reports
    ├── compact-snapshot.md            # Written by PreCompact, consumed at next session start
    ├── missions/                      # Active and archived mission files
    ├── overrides/<skill-name>.md      # Per-skill amendments to base skills
    ├── skills/                        # Project-specific skills
    ├── features/<slug>/               # Feature plans
    └── pipeline-state/                # In-progress implement-feature pipelines
```

Only `settings.json` and `settings.local.json` remain under `.claude/` — Claude Code discovers those two paths itself. Everything else is Mallet's own and lives in `.mallet/`, isolated from the harness namespace.

Whether `.mallet/` is tracked by git is the user's choice. Mallet ships no `.gitignore` into it and never edits a repo's `.gitignore` or excludes without an explicit answer.

## Key paths

| Path | Purpose |
|---|---|
| `~/.claude/CLAUDE.md` | Directives, loaded in every session in every project |
| `~/.claude/settings.json` | Base hook + statusline registrations, merged with user config |
| `~/.claude/framework.json` | Single source of version truth, plus the ownership manifest |
| `~/.claude/skills/` | Framework skills, available everywhere |
| `~/.claude/agents/` | Sub-agent persona definitions |
| `~/.claude/hooks/` | Hook scripts; each resolves data via `$CLAUDE_PROJECT_DIR` |
| `~/.claude/templates/` | Skill and gitignore templates |
| `<project>/.mallet/` | That project's Mallet state |
| `<project>/.mallet/conventions.md` | Project conventions layered on top of the base directives |
| `<project>/.claude/settings.json` | Opt-in hook registrations for that project only |
| `.claude/settings.fragment.json` | *(this repo)* registrations merged into user settings at install |
| `.claude/install-payload.sh` | *(this repo)* shared by `install.md` and the `update` skill |
| `.mallet/features/` | *(this repo)* feature plans, committed directly to master |

On-demand files are documented in the directives and skills that own them — see [`directives.md`](directives.md) and [`skills.md`](skills.md).
