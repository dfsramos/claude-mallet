# Task: persona-trim
Status: done
Deps: 04, 05

## Goal
Reduce CLAUDE.md to directives Claude Code does not already carry, under 9,000 characters.

## Steps
1. Remove or condense in `CLAUDE.md`: "Run commands instead of suggesting them", Tool Preferences bullets duplicated by the built-in tool guidance (keep: stderr suppression, variable-assignment rule, numeric replace_all, Think in Code, Filter before fetching), Context Cache Design, Session Checkpoint turn-count prose, "Verification Before Done" subagent-for-every-change mandate (make it proportional: required for multi-file changes).
2. Keep: Evidence-Based Approach, Communication Style, Interaction Style, Scope of Changes, Implementation Depth, Destructive Operations, Production Awareness, Git Workflow, Skill Authoring, Mission Continuity, Project Context, Skill Overrides.
3. Update skill names to their plugin form where the text invokes them (`mallet:plan-feature` etc.) only after task 09 confirms the runtime names; until then leave bare names.
4. `wc -c CLAUDE.md` < 9000; record before/after in state.md.

## Notes
The 9,000 limit leaves headroom for SessionStart hook output caps; task 09 verifies the actual cap.
