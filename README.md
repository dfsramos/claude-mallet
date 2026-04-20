# ai-framework

A portable configuration framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that customises agent behavior through directives, hooks, and skills.

## Overview

A reusable set of configuration files (`CLAUDE.md` and `.claude/`) that shape how Claude Code operates within any repository. When Claude Code opens a project containing these files, it automatically adopts the defined persona, enforces the specified rules, and gains access to registered hooks and skills.

It is not application code — it is a scaffold for standardising Claude Code behavior.

Two workflows anchor the framework and return the most value per session:

- **Discovery (`/discover`)** — structured codebase analysis that surfaces `.claude/` setup opportunities: detected stacks and services, MCP and skill-pack suggestions, conventions worth capturing, and quick wins Claude can implement immediately.
- **Session wrap-up (`wrap up` / `end session`)** — end-of-session retrospective covering what went well, what went wrong, token-efficiency patterns, and applied improvements to skills, directives, and project memory. The wrap-up is the primary mechanism by which the framework gets better over time.

## Installation

Open any project in Claude Code and say:

```
install the framework from https://github.com/dfsramos/ai-framework
```

Claude will download the latest release tarball, copy the framework files into the target project, preserve any existing `.claude/project/**` content, and write `.claude/framework.json` with the commit hash.

### Manual

```bash
curl -sfL https://github.com/dfsramos/ai-framework/archive/refs/heads/master.tar.gz | tar -xz -C /tmp
cp -r /tmp/ai-framework-master/.claude/hooks /tmp/ai-framework-master/.claude/skills /tmp/ai-framework-master/.claude/templates /path/to/project/.claude/
cp /tmp/ai-framework-master/.claude/statusline.sh /tmp/ai-framework-master/.claude/settings.json /path/to/project/.claude/
cp /tmp/ai-framework-master/CLAUDE.md /path/to/project/
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
| `plan-feature` | "plan a feature", "I want to build X" |
| `systematic-debugging` | Debugging errors or unexpected behaviour |
| `reviewing-sessions` | "wrap up", "end session" |
| `task-calibrate` | High-complexity prompt (auto), or "check model for this" |
| `create-pr` | "create PR", "open a PR" |
| `update` | "update the framework" |

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
