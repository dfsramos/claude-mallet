# Task: hook-output
Status: done
Deps: —

## Goal
Make typecheck.sh and write-guard.sh deliver their messages through channels the model actually reads.

## Steps
1. `.claude/hooks/typecheck.sh`: replace `printf '[typecheck] %s\n'` with `jq -n --arg c "[typecheck] $OUTPUT" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'`.
2. `.claude/hooks/write-guard.sh`: send the refusal to stderr (`>&2`) before `exit 2`.
3. Add `.mallet/features/plugin-slim-down/tests/test-10-hook-output.sh` (same harness style as test-02: BASH_SOURCE repo root, mktemp, fake HOME) asserting: typecheck stdout parses as JSON with `.hookSpecificOutput.additionalContext` (use a stub `npx` on PATH that prints an error and a fixture tsconfig.json); write-guard on an existing file exits 2 with the message on stderr and empty stdout; write-guard on a new path exits 0.

## TDD Checklist
- [ ] Write failing test
- [ ] Confirm test fails (red)
- [ ] Implement
- [ ] Confirm test passes (green)
- [ ] Confirm no regressions

## Notes
Evidence: hooks.md — "For most events, Claude Code writes stdout to the debug log … exceptions are UserPromptSubmit, UserPromptExpansion, SessionStart, and PostModelSwitch". Exit 2 feedback is read from stderr.
