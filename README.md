# ClaudeMallet

<p align="center">
  <img src="assets/claude-mallet.jpg" alt="ClaudeMallet" width="400" />
</p>

> A mallet is the heavy, precise hammer a blacksmith uses to shape raw metal on the anvil — delivering controlled force to forge something strong and purposeful.
> ClaudeMallet is that tool for Claude Code: hammer in directives, hooks, skills, and a consistent persona, transforming raw Claude into a reliable, opinionated, and highly effective coding partner across every project.

A portable configuration framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that customises agent behavior through directives, hooks, and skills.

## Overview

A reusable set of configuration files (`CLAUDE.md` and `.claude/`) that shape how Claude Code operates within any repository. When Claude Code opens a project containing these files, it automatically adopts the defined persona, enforces the specified rules, and gains access to registered hooks and skills.

It is not application code — it is a scaffold for standardising Claude Code behavior.

Three workflows anchor the framework and return the most value per session:

- **Discovery (`/discover`)** — structured codebase analysis that surfaces `.claude/` setup opportunities: detected stacks and services, highest-centrality files (god nodes), MCP and skill-pack suggestions, conventions worth capturing, and quick wins Claude can implement immediately.
- **Session wrap-up (`wrap up` / `end session`)** — end-of-session retrospective covering what went well, what went wrong, token-efficiency patterns, and applied improvements to skills, directives, and project memory. The wrap-up is the primary mechanism by which the framework gets better over time.
- **Architecture decisions (`/adr`)** — captures significant architectural choices in Nygard format (`docs/adr/NNNN-title.md`) so the rationale survives beyond the session. Triggered automatically during feature planning when a significant choice is made.

## Installation

Open any project in Claude Code and say:

```
install the framework from https://github.com/dfsramos/claude-mallet
```

Claude will download the latest release tarball, copy the framework files into the target project, preserve any existing `.claude/project/**` content, and write `.claude/framework.json` with the commit hash.

### Manual

```bash
curl -sfL https://github.com/dfsramos/claude-mallet/archive/refs/heads/master.tar.gz | tar -xz -C /tmp
cp -r /tmp/claude-mallet-master/.claude/hooks /tmp/claude-mallet-master/.claude/skills /tmp/claude-mallet-master/.claude/templates /path/to/project/.claude/
cp /tmp/claude-mallet-master/.claude/statusline.sh /tmp/claude-mallet-master/.claude/settings.json /path/to/project/.claude/
cp /tmp/claude-mallet-master/CLAUDE.md /path/to/project/
chmod +x /path/to/project/.claude/hooks/*.sh
```

Note: manual copy does not write `.claude/framework.json`, so the session-start update check will not run.

## Updating

With the framework installed, say:

```
update the framework
```

The update skill fetches the latest commit via the GitHub API, downloads the tarball, overwrites framework-managed files (preserving `.claude/project/**` and `.claude/settings.local.json`), and updates `.claude/framework.json` with the new version hash.

The session-start hook also checks for updates automatically on each session start and surfaces them to Claude so you can accept or defer the upgrade inline.

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

## Hooks

Hooks run automatically in response to Claude Code events. The framework ships a default set (always active) and an opt-in set activated per project via `/hooks-setup`.

| Hook | Event | Tier | What it does |
|---|---|---|---|
| `session-start.sh` | SessionStart | Default | Injects project memory, restores compact snapshot, checks for framework updates |
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
