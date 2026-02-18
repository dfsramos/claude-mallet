# ai-framework

A portable configuration framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that customizes agent behavior through directives, hooks, skills, and session tracking.

## Overview

This project is a reusable set of configuration files (`CLAUDE.md` and `.claude/` directory) that shape how Claude Code operates within any repository. When Claude Code opens a project containing these files, it automatically adopts the defined persona, enforces the specified rules, and gains access to registered skills and hooks.

It is not application code — it is a scaffold for standardizing Claude Code behavior.

## Installation

Use the installer to deploy the framework into an existing project:

```bash
bash ai-framework/install.sh /path/to/existing-project
```

The installer handles conflict detection, backup options, hook permissions, and `.gitignore` entries. Run with `--dry-run` to preview what would be changed without writing anything.

Alternatively, copy the files manually:

```bash
cp -r ai-framework/source/.claude /path/to/existing-project/
cp ai-framework/source/CLAUDE.md /path/to/existing-project/
```

After installation, customize `CLAUDE.md` and the skills to match your workflow. Claude Code picks up the configuration automatically.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Bash 4+ (for hooks and the installer)

## Documentation

Detailed documentation on individual components is available in the [docs/](docs/) directory:

- [Project Structure](docs/structure.md) — directory layout and file roles
- [Directives](docs/directives.md) — behavioral rules defined in `CLAUDE.md`
- [Hooks](docs/hooks.md) — automatic actions triggered by Claude Code events
- [Skills](docs/skills.md) — reusable capabilities and the skill backlog
