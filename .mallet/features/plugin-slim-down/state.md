# State: plugin-slim-down

## Decisions
<!-- 2026-09-28: Persona via plugin SessionStart hook — plugins cannot ship CLAUDE.md (components.md: "Claude Code doesn't load a CLAUDE.md at the plugin root"). -->
<!-- 2026-09-28: Statusline via /mallet:setup — plugin settings.json honours only `agent` and `subagentStatusLine`. -->
<!-- 2026-09-28: Calibrate reworked — hooks cannot see model/effort and prompt-type hooks cannot inject context, so classification moves into the model; the hook supplies only the effort level. -->
<!-- 2026-09-28: Transition through the paths an installed `update` skill already executes, so no manual step is needed for existing installs. -->
<!-- 2026-09-28: explore-redirect removed rather than fixed — built-in Explore agent covers broad search; Graphify pointer is niche. -->

## Blockers
<!-- - [ ] <description> (check off when resolved) -->
