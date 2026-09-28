# Task: remove-redundant
Status: pending
Deps: 01, 02, 03

## Goal
Remove Mallet components that duplicate built-in Claude Code features.

## Steps
1. Delete `.claude/hooks/push-confirm.sh` and `.claude/hooks/explore-redirect.sh`; remove both from `.claude/skills/hooks-setup/SKILL.md` (typecheck remains the only opt-in hook).
2. Delete `.claude/skills/dispatching-parallel-agents/`; move its three-condition independence test into the CLAUDE.md "Subagent Context Isolation" section; replace references (`grep -rn dispatching-parallel-agents`).
3. Remove `.mallet/memory.md` injection from `.claude/hooks/session-start.sh`; remove memory.md steps from `.claude/skills/checkpoint/SKILL.md` (§2) and `.claude/skills/reviewing-sessions/SKILL.md` (§4a); point both at auto memory (`MEMORY.md` index in the auto-memory directory).
4. Replace `.mallet/lessons.md` in CLAUDE.md "Self-Improvement Loop", checkpoint §1, reviewing-sessions, and `.claude/skills/next-steps/SKILL.md` with auto memory `feedback` entries. `[re-evaluate]` convention moves with it.
5. Remove ultracode scoring from `.claude/hooks/user-prompt-submit.sh` and the "Ultracode Mode" CLAUDE.md section except one line mapping personas to `agentType` names.
6. Existing users' `.mallet/memory.md` and `.mallet/lessons.md` files are never deleted; `/mallet:setup` (task 10) offers a one-time fold into auto memory.
7. `grep -rnE 'memory\.md|lessons\.md|push-confirm|explore-redirect|dispatching-parallel|ultracode' .claude CLAUDE.md` returns only intended residue; update test-02 assertions.

## TDD Checklist
- [ ] Write failing test (test-02: session-start no longer emits memory; user-prompt-submit never emits `[ultracode]`)
- [ ] Confirm test fails (red)
- [ ] Implement
- [ ] Confirm test passes (green)
- [ ] Confirm no regressions

## Notes
The repo's own `.mallet/lessons.md` stays as historical record.
