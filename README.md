# ai-framework

A portable configuration framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that customizes agent behavior through directives, hooks, skills, and session tracking.

## Overview

This project is a reusable set of configuration files (`CLAUDE.md` and `.claude/` directory) that shape how Claude Code operates within any repository. When Claude Code opens a project containing these files, it automatically adopts the defined persona, enforces the specified rules, and gains access to registered skills and hooks.

It is not application code — it is a scaffold for standardizing Claude Code behavior.

## Installation

Open this repo in Claude Code and ask it to install the framework into a target project:

```
install the framework into /path/to/existing-project
```

Claude will inspect the target for existing `.claude/` setup, detect any local customisations that would be overwritten, ask how to handle conflicts, copy the framework files, set hook permissions, and provide context-aware next steps based on the project's stack.

Alternatively, copy the files manually:

```bash
cp -r ai-framework/source/.claude /path/to/existing-project/
cp ai-framework/source/CLAUDE.md /path/to/existing-project/
```

After installation, customize `CLAUDE.md` and the skills to match your workflow. Claude Code picks up the configuration automatically.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Bash 4+ (for hooks)

## Documentation

Detailed documentation on individual components is available in the [docs/](docs/) directory:

- [Project Structure](docs/structure.md) — directory layout and file roles
- [Directives](docs/directives.md) — behavioral rules defined in `CLAUDE.md`
- [Hooks](docs/hooks.md) — automatic actions triggered by Claude Code events
- [Skills](docs/skills.md) — reusable capabilities and the skill backlog
