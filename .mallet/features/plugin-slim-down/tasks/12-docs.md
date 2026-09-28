# Task: docs
Status: done
Deps: 10, 11

## Goal
Update user-facing and internal documentation to describe the plugin.

## Steps
1. `README.md`: Installation = `/plugin marketplace add dfsramos/claude-mallet` + `/plugin install mallet@mallet` + `/mallet:setup`; Updating = plugin updates; "Transitioning from a user-level install"; drop removed components from What's Included and Hooks.
2. `install.md`: replace with the plugin install steps, or delete if README covers it (check inbound links first).
3. `docs/skills.md`, `docs/hooks.md`, `docs/structure.md`, `docs/directives.md`: remove deleted components, document calibrate rework, post-compact hook, persona hook, workflow.
4. `.mallet/conventions.md`: payload paths (`skills/`, `agents/`, `hooks/` at repo root), test command, drop the `.claude/` asymmetry note.
5. Grep for stale references: `grep -rnE '~/.claude/(skills|agents|hooks|templates)|install-payload|framework\.json' README.md docs skills agents hooks persona`.
