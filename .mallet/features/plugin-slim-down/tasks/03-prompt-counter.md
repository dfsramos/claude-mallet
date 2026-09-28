# Task: prompt-counter
Status: done
Deps: —

## Goal
Count only human-typed prompts in the session-watch counter and the statusline turn segment.

## Steps
1. In `.claude/hooks/user-prompt-submit.sh:13` and `.claude/statusline.sh:114`, replace the jq filter with one that keeps user entries whose `.message.content` is a string, or an array with no `tool_result` item, and that are not `isMeta` / `isCompactSummary`. Extract the filter into one shared definition if both files end up in the same plugin dir (task 09); until then, duplicate it with a comment pointing at the twin.
2. Verify against the review transcript `~/.claude/projects/-mnt-c-Repositories-Personal-ai-framework/8d74ff14-30e6-4ae0-aa6e-767bcaeadaf9.jsonl`: count must equal the number of prompts the user actually typed (inspect `.message.content` strings to confirm which are agent hand-backs / notifications and whether they can be excluded by a field; record findings in state.md).
3. Add `test-12-prompt-counter.sh` with a synthetic transcript fixture: 2 typed prompts, 5 tool results, 1 meta entry → count 2 (hook reports next prompt as 3).

## TDD Checklist
- [ ] Write failing test
- [ ] Confirm test fails (red)
- [ ] Implement
- [ ] Confirm test passes (green)
- [ ] Confirm no regressions

## Notes
Review evidence: old filter returned 15 for a session with 2 typed prompts and 13 tool results.
