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

<!-- 2026-09-28 (task 08): kept mallet:code-reviewer as the review stage — workflow agent() cannot invoke slash commands, so /code-review is not reachable from a script. Blocked results end the run and return to the launcher skill, since workflow agents cannot ask the user. Routing covered by test-14 (22 assertions, stubbed agent()). -->

<!-- 2026-09-28 (task 09): plugin lives in plugin/ (marketplace source "./plugin") rather than the repo root, so .mallet/, docs/, and tests/ stay out of the plugin cache and the root CLAUDE.md (kept: pre-plugin update skills abort without it) is not at the plugin root. Marketplace "claude-mallet", plugin "mallet". No version field: users track commits; auto-update is off by default for third-party marketplaces and must be enabled per user in /plugin. Hook output cap is 10,000 chars (hooks.md); persona 8,654. typecheck is registered by the plugin and gated on .mallet/typecheck.enabled, because project settings cannot reference the versioned plugin cache. Live probe (claude -p --plugin-dir): agents resolve as mallet:<name>; calibrate and hooks-setup absent from the model-visible skill list; persona present. Tests moved to tests/. update skill removed from the plugin. -->

<!-- 2026-09-28 (task 10): statusLine points at ${CLAUDE_PLUGIN_DATA}/statusline.sh, refreshed by session-start on every startup (test-16), so the statusline follows plugin updates. The setup skill is model-executed prose; its settings edit is not unit-testable and is exercised in task 13. -->

<!-- 2026-09-28 (task 11): install-payload.sh is now the transition (same path/flags). merge-settings.sh OWNED regex anchored to .claude/hooks/ so a user script sharing a name (e.g. ~/scripts/session-start.sh) is never removed; typecheck added since its script is removed. test-17 (37 assertions) replaces test-08; negative control against the old installer: 26 failures. -->

## Blockers
<!-- - [ ] <description> (check off when resolved) -->
