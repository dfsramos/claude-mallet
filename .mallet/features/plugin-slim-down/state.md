# State: plugin-slim-down

## Decisions
<!-- 2026-09-28: Persona via plugin SessionStart hook — plugins cannot ship CLAUDE.md (components.md: "Claude Code doesn't load a CLAUDE.md at the plugin root"). -->
<!-- 2026-09-28: Statusline via /mallet:setup — plugin settings.json honours only `agent` and `subagentStatusLine`. -->
<!-- 2026-09-28: Calibrate reworked — hooks cannot see model/effort and prompt-type hooks cannot inject context, so classification moves into the model; the hook supplies only the effort level. -->
<!-- 2026-09-28: Transition through the paths an installed `update` skill already executes, so no manual step is needed for existing installs. -->
<!-- 2026-09-28: explore-redirect removed rather than fixed — built-in Explore agent covers broad search; Graphify pointer is niche. -->

<!-- 2026-09-28 (task 03): transcripts mark typed prompts with origin.kind == "human" (promptSource typed / suggestion_accepted); agent hand-backs are isMeta with origin.kind "peer"; skill expansions are isMeta with no origin. Review session: new filter 4 = 4 typed prompts. -->

<!-- 2026-09-28 (task 05 spike): statusline docs list `effort.level` ("Reflects the live session value, including mid-session /effort changes"; absent when the model has no effort parameter) and `model.id`. No live probe needed. Settings fallback runs only when no statusline state exists. -->

<!-- 2026-09-28 (task 06): CLAUDE.md 16,063 -> 8,697 chars. Dropped: Context Cache Design (cache note kept in calibrate skill), Ultracode Mode (native), directives duplicated by the built-in prompt ("run commands", dedicated-tool list). Git Workflow now says "default branch" instead of master for public users. -->

<!-- 2026-09-28 (task 07): kept model aliases (sonnet/haiku) instead of inherit — aliases track the latest model per tier; inherit would run every persona on the parent model. update and preflight stay model-invocable: update is reached from the session-start notice, preflight has a model-side trigger. Only hooks-setup and calibrate are manual-only. Skills support ${CLAUDE_EFFORT} and ${CLAUDE_SKILL_DIR} (skills.md); allowed-tools grants, does not restrict, and is space-separated. -->

## Blockers
<!-- - [ ] <description> (check off when resolved) -->
