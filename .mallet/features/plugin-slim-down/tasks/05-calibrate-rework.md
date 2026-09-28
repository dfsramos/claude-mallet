# Task: calibrate-rework
Status: pending
Deps: 03, 04

## Goal
Surface a one-line model/effort mismatch warning decided by the model itself, with the hook supplying only the active effort level.

## Steps
1. Spike: add a temporary `jq . > "$HOME/.claude/.statusline-probe.json"` line to the installed statusline, capture one render, and record in state.md whether an effort field exists and its path. Remove the probe line and file.
2. `.claude/statusline.sh`: write `{"model":…,"effort":…}` to `${TMPDIR:-/tmp}/mallet-session-<session_id>.json` on each render (effort from step 1's field, else `jq -r '.effortLevel // empty'` of `~/.claude/settings.json`, marked `source:"settings"`).
3. `.claude/hooks/user-prompt-submit.sh`: replace SCORE logic with: read that file by `session_id` from hook input; emit `[calibrate] active model: <m>; effort: <e> (<source>)` only when the value differs from the last one emitted in this session (track in the same file).
4. CLAUDE.md "Task Calibration": replace with the directive — when the request clearly warrants a more capable or cheaper model, or a different effort level, than the active one, say so in one line at the top of the reply naming the `/model` or `/effort` command, then proceed; do not repeat unless the task changes; never for messages from subagents or task notifications. Refer to models relative to the active one and to the environment's current model list — no hardcoded model names.
5. `.claude/skills/task-calibrate/SKILL.md`: rename to `calibrate`, add `disable-model-invocation: true`, rewrite the matrix in relative terms, drop the ultracode persona table (moved to CLAUDE.md in task 04).
6. Test test-13-calibrate.sh: fixture state file → hook emits once, then silent on the same values, then emits on change.

## TDD Checklist
- [ ] Write failing test
- [ ] Confirm test fails (red)
- [ ] Implement
- [ ] Confirm test passes (green)
- [ ] Confirm no regressions

## Notes
Docs: UserPromptSubmit input has no model/effort field; prompt-type hooks return ok/reason only.
