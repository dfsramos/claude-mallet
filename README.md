# ai-framework

A portable configuration framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that customises agent behavior through directives, hooks, and skills.

## Overview

A reusable set of configuration files (`CLAUDE.md` and `.claude/`) that shape how Claude Code operates within any repository. When Claude Code opens a project containing these files, it automatically adopts the defined persona, enforces the specified rules, and gains access to registered hooks and skills.

It is not application code — it is a scaffold for standardising Claude Code behavior.

## Installation

### Remote (recommended)

Open any project in Claude Code and say:

```
install the framework from https://github.com/dfsramos/ai-framework
```

Claude will clone the repo, inspect the target for existing setup, handle conflicts, copy the framework files, and provide next steps. No local checkout required.

### Local

If you have this repo checked out locally, open it in Claude Code and say:

```
install the framework into /path/to/existing-project
```

### Manual

```bash
cp -r source/.claude /path/to/existing-project/
cp source/CLAUDE.md /path/to/existing-project/
```

Note: manual copy does not write `.claude/framework.json`, so the session-start update check will not run.

## Updating

With the framework installed, say:

```
update the framework from https://github.com/dfsramos/ai-framework
```

The update skill diffs each installed file against the latest version, flags local customisations as conflicts for you to resolve, and updates `.claude/framework.json` with the new version hash.

The session-start hook also checks for updates automatically on each session start (requires `gh`).

## What's Included

| Skill | Trigger |
|-------|---------|
| `discover` | "discover this project", `/discover` |
| `plan-feature` | "plan a feature", "I want to build X" |
| `systematic-debugging` | Debugging errors or unexpected behaviour |
| `reviewing-sessions` | "wrap up", "end session" |
| `update` | "update the framework from \<url\>" |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Bash 4+ (for hooks)
- `jq` (required — hook parses session input JSON)
- `gh` CLI (optional — enables session-start update checks)

## Documentation

- [Project Structure](docs/structure.md) — directory layout and file roles
- [Directives](docs/directives.md) — behavioral rules defined in `CLAUDE.md`
- [Hooks](docs/hooks.md) — automatic actions triggered by Claude Code events
- [Skills](docs/skills.md) — reusable capabilities and the skill backlog
