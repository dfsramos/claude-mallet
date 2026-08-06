# Task: hook-paths
Status: done
Deps: —

## Goal
Repoint every hook's state path from `.claude/project/` to `.mallet/`, and `framework.json` from the project dir to `~/.claude/`.

## Context
Hooks locate their data through `$CLAUDE_PROJECT_DIR`, which is why relocating the scripts to `~/.claude/` needs no behavioural change — only the path segment after it changes. `framework.json` is the exception: it becomes a single user-level file, so it resolves against `$HOME` instead.

One bug the move introduces: `pre-compact.sh` *writes* its snapshot. Today `.claude/project/` always exists because the installer creates it (`install.md:63`); `.mallet/` may not exist in a repo that has never used Mallet state. The write needs a `mkdir -p`.

## Steps

1. `.claude/hooks/session-start.sh`:
   - Line 8: `${CLAUDE_PROJECT_DIR}/.claude/project/memory.md` → `${CLAUDE_PROJECT_DIR}/.mallet/memory.md`
   - Line 19: `${CLAUDE_PROJECT_DIR}/.claude/project/compact-snapshot.md` → `${CLAUDE_PROJECT_DIR}/.mallet/compact-snapshot.md`
   - Line 29: `${CLAUDE_PROJECT_DIR}/.claude/framework.json` → `${HOME}/.claude/framework.json`

2. `.claude/hooks/pre-compact.sh`:
   - Line 10: `${CLAUDE_PROJECT_DIR}/.claude/project/compact-snapshot.md` → `${CLAUDE_PROJECT_DIR}/.mallet/compact-snapshot.md`
   - Line 36: `${CLAUDE_PROJECT_DIR}/.claude/project/missions/active.md` → `${CLAUDE_PROJECT_DIR}/.mallet/missions/active.md`
   - Immediately before the first write to `$SNAPSHOT_FILE`, insert:
     ```bash
     mkdir -p "$(dirname "$SNAPSHOT_FILE")" || exit 0
     ```
     Exit 0 rather than non-zero on failure — a PreCompact hook must never block compaction.

3. `.claude/hooks/explore-redirect.sh`:
   - Line 15 (comment): `.claude/project/discovery-*.md` → `.mallet/discovery-*.md`
   - Line 46: `"${CLAUDE_PROJECT_DIR}/.claude/project/discovery-"*.md` → `"${CLAUDE_PROJECT_DIR}/.mallet/discovery-"*.md`
   - Line 49 (user-facing message): `.claude/project/${REPORT_NAME}` → `.mallet/${REPORT_NAME}`

4. `.claude/statusline.sh`:
   - Line 10: `FRAMEWORK_JSON="${PROJECT_DIR}/.claude/framework.json"` → `FRAMEWORK_JSON="${HOME}/.claude/framework.json"`
   - Leave lines 9 and 75–78 intact — `PROJECT_DIR` is still needed to resolve the git repo and branch.

5. Leave `.claude/hooks/typecheck.sh:17` (`PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"`) unchanged — it resolves the project being linted, not Mallet state.

6. Confirm `.claude/hooks/user-prompt-submit.sh` and `.claude/hooks/write-guard.sh` need no edits (neither references a `.claude/` path).

## TDD Checklist
- [x] Write failing test: create `<scratchpad>/fixture-repo/.mallet/` containing `memory.md` and `missions/active.md`; run each hook with `CLAUDE_PROJECT_DIR=<scratchpad>/fixture-repo` and assert the content is picked up
- [x] Confirm tests fail (red) against the current `.claude/project/` paths
- [x] Apply steps 1–6
- [x] Confirm tests pass (green)
- [x] Assert `pre-compact.sh` creates `.mallet/` when absent and still exits 0 when the directory cannot be created (test with a read-only fixture dir)
- [x] Assert `session-start.sh` and `explore-redirect.sh` exit 0 and emit nothing when `.mallet/` is absent entirely
- [x] Regression: `grep -rn '\.claude/project' .claude/hooks/ .claude/statusline.sh` returns no matches

## Notes
Task 04 makes further changes to `session-start.sh` and `statusline.sh`; it depends on this task to avoid edit conflicts.
