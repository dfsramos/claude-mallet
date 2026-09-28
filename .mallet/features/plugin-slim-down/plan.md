# Feature: plugin-slim-down
Status: planning
Created: 2026-09-28
Branch: — (this repo commits directly to master per `.mallet/conventions.md`)

## Goal
Cut Mallet down to what Claude Code does not already provide, fix its silently broken hooks, and ship it as a plugin with a one-shot transition for existing user-level installs.

## Context
A 2026-09-28 review against current Claude Code docs found three hooks whose output never reaches the model (PreToolUse/PostToolUse/PreCompact plain stdout goes to the debug log only), a turn counter that counts tool results as prompts (15 counted vs 2 real in the review session), and large overlap with built-ins: auto memory, `ask` permission rules, `/effort ultracode`, `/code-review`, Workflows, plugins. Plugins cannot ship `CLAUDE.md` or the main `statusLine` (only `agent` and `subagentStatusLine` settings take effect), so the persona moves to a plugin SessionStart hook and the statusline to a `/mallet:setup` skill. Installed `update` skills run `$WORK/.claude/install-payload.sh`, `$WORK/.claude/merge-settings.sh`, then `~/.claude/skills/migrate/detect.sh`; the final release keeps scripts at those paths to perform the transition automatically.

## Decisions (user, 2026-09-28)
- Persona delivered by plugin SessionStart hook, not CLAUDE.md or output style.
- task-calibrate reworked, not removed: in-model classification + hook-supplied effort level.
- Existing installs transition via one final `update` run.
- Plugin agents are namespaced `mallet:<name>` at runtime.

## Tasks
- [x] 01-hook-output — typecheck emits JSON additionalContext; write-guard reason to stderr [deps: —] [parallel: no]
- [ ] 02-compact-continuity — replace pre-compact snapshot with a SessionStart `compact` hook [deps: —] [parallel: no]
- [ ] 03-prompt-counter — count only human prompts in user-prompt-submit.sh and statusline.sh [deps: —] [parallel: no]
- [ ] 04-remove-redundant — remove memory.md/lessons.md machinery, push-confirm, explore-redirect, dispatching-parallel-agents, ultracode scoring [deps: 01, 02, 03] [parallel: no]
- [ ] 05-calibrate-rework — statusline records effort, hook injects it, directive replaces regex scoring, skill becomes manual [deps: 03, 04] [parallel: no]
- [ ] 06-persona-trim — cut CLAUDE.md to Mallet-specific directives, under 9,000 characters [deps: 04, 05] [parallel: no]
- [ ] 07-frontmatter — read-only review agents, effort fields, manual-only skills, contract and template relocated [deps: 04] [parallel: no]
- [ ] 08-pipeline-workflow — implement-feature becomes workflows/implement-feature.js [deps: 07] [parallel: no]
- [ ] 09-plugin-layout — move payload to plugin layout with manifest, marketplace, hooks.json, persona hook [deps: 06, 07, 08] [parallel: no]
- [ ] 10-setup-skill — /mallet:setup installs the statusline [deps: 09] [parallel: no]
- [ ] 11-transition — final-release install-payload.sh / merge-settings.sh / detect.sh shims move user-level installs to the plugin [deps: 09] [parallel: no]
- [ ] 12-docs — README, install.md, docs/*, conventions.md reflect the plugin [deps: 10, 11] [parallel: no]
- [ ] 13-verify — tests, `claude plugin validate`, local plugin load, independent review [deps: 12] [parallel: no]
