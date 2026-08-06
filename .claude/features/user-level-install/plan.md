# Feature: user-level-install
Status: in-progress
Created: 2026-07-31
Branch: — (this repo commits directly to master per `.claude/project/CLAUDE.md`)

## Goal
Move the Mallet core to a single user-level install at `~/.claude/`, relocate all per-repo state to `<root>/.mallet/`, and ship a migration that surgically cleans the existing per-project installs.

## Context
Mallet is currently installed per repo. Eight installs exist across three versions (`2c37851` ×5, `275d864` ×2 from April, and exocortex's schema-broken `{"commit": "2ae59d1"}`), two still recording the pre-rename `dfsramos/ai-framework`. Four of seven target repos needed hand-written `.git/info/exclude` entries; the two without them show `?? .claude/` in every `git status`. `install.md:46` deletes the target repo's own `CLAUDE.md`, and Mallet's persona is committed into exocortex's git history as a stale April copy.

The enabling insight: every hook already resolves its *data* through `$CLAUDE_PROJECT_DIR`, so relocating the *scripts* to `~/.claude/` changes only registration paths — hook behaviour is untouched. Separately, `.claude/project/skills/` is confirmed **not** harness-discovered (`harvest` exists on disk but is absent from the session's registered skill list), so nearly all state is free to move to `.mallet/`. Only `settings.json` and `settings.local.json` are pinned to `.claude/` by the harness.

Legacy `CLAUDE.md` files are stripped surgically rather than deleted: fetching the exact historical payload by the SHA in `framework.json` and diffing recovers precisely the project-authored delta. Verified against exocortex — `git show 2ae59d1:CLAUDE.md | diff - exocortex/CLAUDE.md` yields exactly its 16-line `## Vault Context` section and nothing else.

## Canonical path mapping

Used by tasks 02, 03, 05, 09, 10. Any reference not in this table stays unchanged.

| Old | New |
|---|---|
| `.claude/project/CLAUDE.md` | `.mallet/conventions.md` |
| `.claude/project/memory.md` | `.mallet/memory.md` |
| `.claude/project/lessons.md` | `.mallet/lessons.md` |
| `.claude/project/skill-backlog.md` | `.mallet/skill-backlog.md` |
| `.claude/project/task-notes.md` | `.mallet/task-notes.md` |
| `.claude/project/compact-snapshot.md` | `.mallet/compact-snapshot.md` |
| `.claude/project/discovery-*.md` | `.mallet/discovery-*.md` |
| `.claude/project/missions/` | `.mallet/missions/` |
| `.claude/project/overrides/` | `.mallet/overrides/` |
| `.claude/project/skills/` | `.mallet/skills/` |
| `.claude/features/` | `.mallet/features/` |
| `.claude/pipeline-state/` | `.mallet/pipeline-state/` |
| `.claude/framework.json` | `~/.claude/framework.json` |
| `.claude/settings.json` (base hook registrations) | `~/.claude/settings.json` (jq-merged) |
| `.claude/settings.json` (opt-in hook registrations) | unchanged — stays per repo |
| `.claude/settings.local.json` | unchanged — never touched |

## VCS policy: not Mallet's call

Mallet ships no `.gitignore` into `.mallet/` and never edits a repo's `.gitignore` or `.git/info/exclude`. Install and migrate **present** the options and act only on an explicit answer:

| Option | Mechanism |
|---|---|
| Ignore on this machine, every repo | add `.mallet/` to `~/.config/git/ignore` (or whatever `core.excludesFile` points at) |
| Ignore in one repo only | add `.mallet/` to that repo's `.git/info/exclude` |
| Commit it | do nothing; optionally copy the transient-split template from `~/.claude/templates/mallet-gitignore` |
| Decide later | do nothing |

Absent an answer, nothing is written. An AI framework should not impose a VCS policy on the repos it is installed into.

## Tracked files are never modified

Git-tracked `CLAUDE.md` files are left completely alone — no strip, no diff, no suggested command. The surgical strip applies only to **untracked** `CLAUDE.md`, which covers most of the fleet.

## Tasks
- [x] 01-settings-fragment — Convert `.claude/settings.json` to a `$HOME`-pathed merge fragment and define the jq merge routine [deps: —] [parallel: yes]
- [x] 02-hook-paths — Repoint hook data paths to `.mallet/` and `framework.json` to `~/.claude/` [deps: —] [parallel: yes]
- [x] 03-skill-paths — Rewrite the 110 `.claude/project|features|pipeline-state` references across CLAUDE.md, skills, and agents [deps: —] [parallel: yes]
- [x] 04-hook-hardening — Fix `statusline.sh` hard-exit and add update-check caching [deps: 02] [parallel: no]
- [x] 05-migrate-skill — Author the `migrate` skill: detection, backup, CLAUDE.md strip, settings pruning, state move [deps: 01] [parallel: yes]
- [x] 06-install-rewrite — Rewrite `install.md` for user-level install with scan-and-clean [deps: 01, 05] [parallel: yes]
- [x] 07-legacy-detect — Add legacy-payload detection to `session-start.sh` [deps: 02, 05] [parallel: yes]
- [x] 08-update-skill — Rewrite the `update` skill for user-level with jq merge [deps: 01] [parallel: yes]
- [ ] 09-docs — Update `docs/` and `README.md` for parity [deps: 01, 02, 03, 04, 05, 06, 07, 08] [parallel: no]
- [ ] 10-self-migrate — Migrate this repo to `.mallet/`, then run migration across the 8 installs as live validation [deps: 09] [parallel: no]

## Waves
| Wave | Tasks |
|---|---|
| 1 | 01, 02, 03 |
| 2 | 04, 05, 08 |
| 3 | 06, 07 |
| 4 | 09 |
| 5 | 10 |

## Supporting Skills
None. No knowledge-skill signals — this is filesystem and shell work, not a domain with stable external conventions.
