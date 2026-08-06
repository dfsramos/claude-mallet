# ClaudeMallet

<p align="center">
  <img src="assets/claude-mallet.jpg" alt="ClaudeMallet" width="400" />
</p>

> A mallet is the heavy, precise hammer a blacksmith uses to shape raw metal on the anvil — delivering controlled force to forge something strong and purposeful.
> ClaudeMallet is that tool for Claude Code: hammer in directives, hooks, skills, and a consistent persona, transforming raw Claude into a reliable, opinionated, and highly effective coding partner across every project.

A portable configuration framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that customises agent behavior through directives, hooks, and skills.

## Overview

A configuration framework installed **once per machine** at `~/.claude/`. Every Claude Code session, in every project, adopts the defined persona, enforces the specified rules, and gains access to the registered hooks and skills.

Nothing is written into your repositories. A project gains a `.mallet/` directory only when Mallet has something project-specific to store there — conventions, memory, lessons, feature plans. Your repo's own `CLAUDE.md`, if it has one, is never touched.

It is not application code — it is a scaffold for standardising Claude Code behavior.

```
~/.claude/                     installed once, applies everywhere
├── CLAUDE.md                  directives and persona
├── skills/  agents/  hooks/  templates/
├── statusline.sh
├── settings.json              merged, never overwritten
└── framework.json             single source of version truth

<any-repo>/                    only what that project needs
├── CLAUDE.md                  yours, untouched
├── .claude/settings.local.json    permissions, untouched
└── .mallet/                   Mallet's project state
    ├── conventions.md  memory.md  lessons.md
    ├── missions/  overrides/  skills/
    └── features/
```

Three workflows anchor the framework and return the most value per session:

- **Discovery (`/discover`)** — structured codebase analysis that surfaces `.claude/` setup opportunities: detected stacks and services, highest-centrality files (god nodes), MCP and skill-pack suggestions, conventions worth capturing, and quick wins Claude can implement immediately.
- **Session wrap-up (`wrap up` / `end session`)** — end-of-session retrospective covering what went well, what went wrong, token-efficiency patterns, and applied improvements to skills, directives, and project memory. The wrap-up is the primary mechanism by which the framework gets better over time.
- **Architecture decisions (`/adr`)** — captures significant architectural choices in Nygard format (`docs/adr/NNNN-title.md`) so the rationale survives beyond the session. Triggered automatically during feature planning when a significant choice is made.

## Installation

Open any project in Claude Code and say:

```
install the framework from https://github.com/dfsramos/claude-mallet
```

Claude installs into `~/.claude/`, taking a backup first. The install is machine-wide, so the directives apply in every project you open — including ones unrelated to this install.

Existing config is preserved, not clobbered:

- `~/.claude/settings.json` is **merged** — your `model`, `effortLevel`, `enabledPlugins`, and your own hooks survive.
- Skills, agents, templates, and hooks are replaced **per entry**. Anything you authored yourself stays, and is reported back to you as preserved.
- An existing `~/.claude/CLAUDE.md` is backed up to `CLAUDE.md.pre-mallet-<date>` and you are asked before it is replaced.

The installer then offers to clean up any older per-project installs it finds (see below) and asks how you want `.mallet/` treated by git.

### Manual

```bash
curl -sfL https://github.com/dfsramos/claude-mallet/archive/refs/heads/master.tar.gz | tar -xz -C /tmp
bash /tmp/claude-mallet-master/.claude/install-payload.sh \
  --from /tmp/claude-mallet-master --repo dfsramos/claude-mallet --sha "$(git ls-remote https://github.com/dfsramos/claude-mallet master | cut -f1)"
bash /tmp/claude-mallet-master/.claude/merge-settings.sh \
  /tmp/claude-mallet-master/.claude/settings.fragment.json
```

Both scripts are idempotent and take backups. `install-payload.sh` writes `~/.claude/framework.json` including the manifest, so the session-start update check works after a manual install.

## Migrating from a per-project install

Mallet used to install into each repository. If you have those, say:

```
clean up the old Mallet installs
```

Per repo, the `migrate` skill:

- **moves** `.claude/project/`, `.claude/features/`, and `.claude/pipeline-state/` into `.mallet/` — nothing is discarded, including files it does not recognise
- renames `.claude/project/CLAUDE.md` to `.mallet/conventions.md`, ending the two-files-called-CLAUDE.md ambiguity
- **deletes** the old framework payload, but **only files git does not track**
- prunes the base-hook registrations out of `.claude/settings.json`, keeping your per-project opt-in hooks and repointing them at `~/.claude/hooks/`
- strips Mallet's directives out of an **untracked** `CLAUDE.md`, keeping whatever you added, by diffing against the exact historical payload for the version that repo recorded

What it will not do:

- **touch a git-tracked file.** A committed `CLAUDE.md` is left exactly as it is — reported, never modified.
- **touch `.claude/settings.local.json`.**
- **decide your VCS policy.** Mallet ships no `.gitignore` into `.mallet/` and never edits yours. You are asked once whether to ignore `.mallet/` machine-wide, per repo, or not at all.
- **delete anything without a backup.** Each repo is tarred to `~/.claude/mallet-migration-backup-<timestamp>-<repo>.tar.gz` first; a repo whose backup fails is skipped whole.

Repos the installer cannot reach are caught later: the session-start hook notices a leftover payload and offers cleanup the next time you open that project.

## Updating

With the framework installed, say:

```
update the framework
```

One install means one update. The skill fetches the latest commit, replaces each payload entry, merges settings, and reconciles the manifest — removing only what the new release dropped, and leaving anything you authored yourself alone.

The session-start hook checks for updates and surfaces them inline so you can accept or defer. The result is cached for 24 hours at `~/.claude/.mallet-update-check`, because the hook now runs in every session in every directory and the unauthenticated GitHub API allows 60 requests an hour. A failed check is never cached as "up to date".

## What's Included

| Skill | Trigger |
|-------|---------|
| `discover` | "discover this project", `/discover` |
| `adr` | "record this decision", "create an ADR", `/adr` |
| `plan-feature` | "plan a feature", "I want to build X" |
| `implement-feature` | "implement this feature", "add X functionality" |
| `systematic-debugging` | Debugging errors or unexpected behaviour |
| `reviewing-sessions` | "wrap up", "end session" |
| `task-calibrate` | High-complexity prompt (auto), or "check model for this" |
| `hooks-setup` | "set up hooks", "enable typecheck", `/hooks-setup` |
| `preflight` | Environment issues suspected before git-heavy work, `/preflight` |
| `create-pr` | "create PR", "open a PR" |
| `receiving-code-review` | Code review returned and needs actioning |
| `dispatching-parallel-agents` | 3+ independent failures or workstreams |
| `update` | "update the framework" |
| `migrate` | "clean up the old Mallet installs", `/migrate` |

## Hooks

Hooks run automatically in response to Claude Code events. The scripts live at `~/.claude/hooks/` and are shared by every project; each one locates its *data* through `$CLAUDE_PROJECT_DIR`, so it reads the current project's `.mallet/` state.

The default set is registered globally in `~/.claude/settings.json` at install. The opt-in set is registered **per project** via `/hooks-setup` — the script is global, the choice is local, because `typecheck.sh` is language-specific.

| Hook | Event | Tier | What it does |
|---|---|---|---|
| `session-start.sh` | SessionStart | Default | Injects project memory, restores compact snapshot, checks for framework updates (24h cache), flags a leftover per-project install |
| `user-prompt-submit.sh` | UserPromptSubmit | Default | Complexity scorer (triggers `task-calibrate`) and turn counter |
| `write-guard.sh` | PreToolUse `Write` | Default | Blocks `Write` on existing files — enforces `Edit` |
| `pre-compact.sh` | PreCompact | Default | Captures git state and active mission before compaction; restores on next session start |
| `typecheck.sh` | PostToolUse `Edit` | Opt-in | Runs the type-checker after every file edit (TypeScript / PHP) |
| `push-confirm.sh` | PreToolUse `Bash` | Opt-in | Advisory warning before `git push` |
| `explore-redirect.sh` | PreToolUse `Bash` | Opt-in | Suggests Graphify or discovery report before broad grep/find searches |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Bash 4+ (for hooks)
- `jq` (required — hook parses session input JSON)
- `curl` (required — hook queries GitHub for update checks)

## Documentation

- [Project Structure](docs/structure.md) — directory layout and file roles
- [Directives](docs/directives.md) — behavioral rules defined in `CLAUDE.md`
- [Hooks](docs/hooks.md) — automatic actions triggered by Claude Code events
- [Skills](docs/skills.md) — reusable capabilities and the skill backlog
