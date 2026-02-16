# ai-framework

A portable configuration framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that customizes agent behavior through directives, hooks, skills, and session tracking.

## Overview

This project is a reusable set of configuration files (`CLAUDE.md` and `.claude/` directory) that shape how Claude Code operates within any repository. When Claude Code opens a project containing these files, it automatically adopts the defined persona, enforces the specified rules, and gains access to registered skills and hooks.

It is not application code — it is a scaffold for standardizing Claude Code behavior.

## Usage

Copy the configuration files into an existing project, or clone this repo as a starting point.

```bash
cp -r ai-framework/source/.claude /path/to/existing-project/
cp ai-framework/source/CLAUDE.md /path/to/existing-project/
```

Customize `CLAUDE.md` and the skills to match your workflow. Claude Code picks up the configuration automatically.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Bash (for hooks)

## Documentation

Detailed documentation on individual components is available in the [docs/](docs/) directory:

- [Project Structure](docs/structure.md) — directory layout and file roles
- [Directives](docs/directives.md) — behavioral rules defined in `CLAUDE.md`
- [Hooks](docs/hooks.md) — automatic actions triggered by Claude Code events
- [Skills](docs/skills.md) — reusable capabilities and the skill backlog
