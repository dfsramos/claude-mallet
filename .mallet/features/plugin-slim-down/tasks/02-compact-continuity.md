# Task: compact-continuity
Status: done
Deps: —

## Goal
Restore git and mission state after compaction in the same session by emitting it from a SessionStart `compact` hook.

## Steps
1. Create `.claude/hooks/post-compact.sh`: prints `<post-compact-state>` with branch, `git status --short | head -15`, `git log --oneline -5`, and `.mallet/missions/*.md` filenames plus the full `active.md` if present. Exit 0 always.
2. `.claude/settings.fragment.json`: add a `SessionStart` entry with matcher `compact` running `post-compact.sh`; delete the `PreCompact` entry.
3. Delete `.claude/hooks/pre-compact.sh`; remove the compact-snapshot block from `.claude/hooks/session-start.sh`.
4. `.claude/merge-settings.sh`: confirm Mallet-owned entry detection removes the now-unshipped PreCompact registration from existing settings (extend test-01 if it does not).
5. Update `.mallet/features/user-level-install/tests/test-02-hooks.sh`: drop snapshot assertions; add test-11-post-compact.sh asserting branch and mission content appear in output and exit code is 0 outside a git repo.

## TDD Checklist
- [ ] Write failing test
- [ ] Confirm test fails (red)
- [ ] Implement
- [ ] Confirm test passes (green)
- [ ] Confirm no regressions

## Notes
Old design: PreCompact stdout never reached compaction; the snapshot file was consumed by the next `startup` session, i.e. the wrong one.
