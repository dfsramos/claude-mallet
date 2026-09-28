# State: plugin-slim-down

## Decisions
<!-- 2026-09-28: Persona via plugin SessionStart hook — plugins cannot ship CLAUDE.md (components.md: "Claude Code doesn't load a CLAUDE.md at the plugin root"). -->
<!-- 2026-09-28: Statusline via /mallet:setup — plugin settings.json honours only `agent` and `subagentStatusLine`. -->
<!-- 2026-09-28: Calibrate reworked — hooks cannot see model/effort and prompt-type hooks cannot inject context, so classification moves into the model; the hook supplies only the effort level. -->
<!-- 2026-09-28: Transition through the paths an installed `update` skill already executes, so no manual step is needed for existing installs. -->
<!-- 2026-09-28: explore-redirect removed rather than fixed — built-in Explore agent covers broad search; Graphify pointer is niche. -->

<!-- 2026-09-28 (task 03): transcripts mark typed prompts with origin.kind == "human" (promptSource typed / suggestion_accepted); agent hand-backs are isMeta with origin.kind "peer"; skill expansions are isMeta with no origin. Review session: new filter 4 = 4 typed prompts. -->

<!-- 2026-09-28 (task 05 spike): statusline docs list `effort.level` ("Reflects the live session value, including mid-session /effort changes"; absent when the model has no effort parameter) and `model.id`. No live probe needed. Settings fallback runs only when no statusline state exists. -->

## Blockers
<!-- - [ ] <description> (check off when resolved) -->
