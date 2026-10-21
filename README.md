# ClaudeMallet

<p align="center">
  <img src="assets/claude-mallet.jpg" alt="ClaudeMallet" width="400" />
</p>

> A mallet is the heavy, precise hammer a blacksmith uses to shape raw metal on the anvil — delivering controlled force to forge something strong and purposeful.
> ClaudeMallet is that tool for Claude Code: hammer in directives, hooks, skills, and a consistent persona, transforming raw Claude into a reliable, opinionated, and highly effective coding partner across every project.

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that customises agent behavior through a persona, hooks, skills, and sub-agents.

## Overview

This repository is both a Claude Code plugin **marketplace** (`.claude-plugin/marketplace.json`) and the single plugin it hosts, `mallet` (`plugin/`). Installing the plugin gives every session, in every project, the Mallet persona, its skills and sub-agents, and its hooks — no per-project setup and nothing written into your repositories.

Plugins cannot ship a `CLAUDE.md`, so the persona (`plugin/persona/PERSONA.md`) is injected at session start by a hook instead (`plugin/hooks/persona.sh`), re-injected after `/clear` and `/compact` since those drop earlier context. Git conventions are not in the persona: they are a project matter, so Mallet ships its defaults as `plugin/rules/git.md` and, in a repository that states none of its own, applies them for the session and offers to add them as `.claude/rules/git.md`.

A project only gains a `.mallet/` directory when Mallet has something project-specific to store there — feature plans. Your repo's own `CLAUDE.md`, if it has one, is never touched; the one file Mallet offers to add is `.claude/rules/git.md`, and only when you agree.

Three workflows anchor the plugin and return the most value per session:

- **Feature planning (`/mallet:plan-feature`)** — intake, a design approval gate (with `/mallet:council` and `/mallet:adr` on offer for choices that are expensive to reverse), decomposition into tasks, and wave-based execution; plans are committed to the default branch so they stay visible from every branch and resume across sessions.
- **Session wrap-up (`/mallet:reviewing-sessions`, or "wrap up")** — end-of-session retrospective covering what went well, what went wrong, token-efficiency patterns, applied improvements to skills and rules, and a memory entry for work that continues next session.
- **Architecture decisions (`/mallet:adr`)** — captures significant architectural choices in Nygard format (`docs/adr/NNNN-title.md`) so the rationale survives beyond the session. Offered at `/mallet:plan-feature`'s design gate when the approved design makes a significant architectural choice.

## Installation

In Claude Code:

```
/plugin marketplace add dfsramos/claude-mallet
/plugin install mallet@claude-mallet
/mallet:setup
```

`/mallet:setup` handles what a plugin cannot configure on its own: registering the statusline (plugins can only set `agent`/`subagentStatusLine`, not the main `statusLine`), and offering to turn on auto-update.

There is no version field: the plugin has no pinned release, so you track commits on the marketplace's default branch. [CHANGELOG.md](CHANGELOG.md) lists what each update changes, newest first.

**Auto-update** is off by default for third-party marketplaces. `/mallet:setup` offers to turn it on; otherwise use `/plugin` → **Marketplaces** → **claude-mallet** → **Enable auto-update**, or set `"autoUpdate": true` on the marketplace's `extraKnownMarketplaces` entry in `~/.claude/settings.json` (see [install.md](install.md)). Without it, update on demand with `/plugin marketplace update claude-mallet`.

## What's Included

### Skills

| Skill | Trigger |
|-------|---------|
| `/mallet:adr` | "record this decision", "create an ADR" |
| `/mallet:council` | "council this", "pressure-test this decision" |
| `/mallet:plan-feature` | "plan a feature", "I want to build X" |
| `/mallet:systematic-debugging` | Debugging errors or unexpected behaviour |
| `/mallet:reviewing-sessions` | "wrap up", "end session" |
| `/mallet:setup` *(manual-only)* | Right after installing the plugin |
| `/mallet:create-pr` | "create PR", "open a PR" |
| `/mallet:receiving-code-review` | A code review has just been returned |
| `/mallet:next-steps` | "what's left", "what's next" |
| `/mallet:write-task` | "create a ticket", "write the task description", "write a handover as a task" |

Manual-only skills carry `disable-model-invocation: true` — Claude will not invoke them on its own; they run only from their slash command.

### Agents

Sub-agents, namespaced `mallet:<name>` at runtime. Two review a change set on request, from Claude or from you:

| Agent | Persona | Role | Model / Effort |
|---|---|---|---|
| `code-reviewer` | Clifford | Senior review — blocking vs non-blocking | opus / high |
| `scope-validator` | Sylvie | Confirms acceptance criteria met, no scope creep | sonnet / high |

The `council` skill convenes four advisors, each starting from the same written brief in its own context:

| Agent | Persona | Lens | Model / Effort |
|---|---|---|---|
| `council-contrarian` | Cassandra | What would make the decision fail | opus / high |
| `council-first-principles` | Felix | Whether it addresses the right problem | opus / high |
| `council-expansionist` | Esme | The upside and the options being missed | sonnet / high |
| `council-executor` | Ezra | The first concrete steps and what blocks them | sonnet / high |

Every agent is restricted to `disallowedTools: Edit, Write, NotebookEdit`.

### Hooks

| Hook | Event | What it does |
|---|---|---|
| `persona.sh` | SessionStart (`startup\|resume\|clear\|compact`) | Injects `PERSONA.md` — the only way a plugin can deliver directives |
| `session-start.sh` | SessionStart (`startup\|resume\|clear\|compact`) | On startup and resume, refreshes the statusline copy in `${CLAUDE_PLUGIN_DATA}` and names leftover `.mallet/` files that nothing reads since 2026-10-20, with where their content belongs now; in a git repository with no Git conventions of its own, prints Mallet's defaults and has Claude offer them as `.claude/rules/git.md` |
| `post-compact.sh` | SessionStart (`compact`) | Prints branch, uncommitted changes, and recent commits right after compaction |

Every Mallet hook is a `SessionStart` hook, the one event where plain stdout reaches the model without a JSON envelope. What earlier hooks did — compaction reminders, blocking `Write` on existing files, guarding destructive commands, type checking after edits — is now a Claude Code setting or an official plugin; [`docs/hooks.md`](docs/hooks.md#removed-hooks) lists each replacement.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI with plugin support
- `bash`
- `jq`
- `git`

Node is not required.

## Documentation

- [Project Structure](docs/structure.md) — directory layout and file roles
- [Directives](docs/directives.md) — behavioral rules defined in the persona
- [Hooks](docs/hooks.md) — automatic actions triggered by Claude Code events
- [Skills](docs/skills.md) — reusable capabilities
