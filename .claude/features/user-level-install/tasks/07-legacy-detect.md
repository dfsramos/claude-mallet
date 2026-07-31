# Task: legacy-detect
Status: pending
Deps: 02, 05

## Goal
Have `session-start.sh` notice a leftover per-project Mallet payload in the current repo and offer cleanup in one line.

## Context
The installer's scan (task 06 step 12) catches repos reachable from `~/.claude/projects/` or a supplied scan root. This is the second, independent path: it catches anything the scan missed — a repo cloned later, a machine where the scan was declined, or a friend who migrated before a given repo existed. Self-healing, so nothing depends on remembering which repos were affected.

It must stay quiet. `session-start.sh` output is injected into every session in every directory, so this can be at most a couple of lines, must be suppressible, and must never delay startup.

## Steps

1. Append a new section to `.claude/hooks/session-start.sh`, before the final `exit 0`:

   ```bash
   # ── Legacy per-project install detection ────────────────────────────────────
   # Mallet is installed at ~/.claude/. A payload inside the project means a
   # pre-migration per-project install is still present.

   LEGACY_MARKER="${CLAUDE_PROJECT_DIR}/.mallet/.migration-declined"
   if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ ! -f "$LEGACY_MARKER" ]; then
     if [ -f "${CLAUDE_PROJECT_DIR}/.claude/framework.json" ] \
        || { [ -f "${CLAUDE_PROJECT_DIR}/.claude/skills/update/SKILL.md" ] \
             && [ -f "${CLAUDE_PROJECT_DIR}/.claude/agents/_contract.md" ]; }; then
       echo "--- Legacy Mallet Install Detected ---"
       echo "This project contains a per-project Mallet payload; Mallet is now installed at ~/.claude/."
       echo "Offer to run the migrate skill to clean it up. If the user declines, create ${CLAUDE_PROJECT_DIR}/.mallet/.migration-declined so this notice stops."
       echo "--- End Legacy Mallet Install Detected ---"
     fi
   fi
   ```

2. Use the same detection predicate as the `migrate` skill's Phase 2 — file presence, never schema. Keep the two in sync; if one changes, change both.

3. Do not add any network call, `find`, or recursive traversal. The check is at most three `-f` tests.

4. Document the suppression file in `docs/hooks.md` as part of task 09.

## TDD Checklist
- [ ] Write failing test: fixture repo containing `.claude/framework.json`; run `session-start.sh` with `CLAUDE_PROJECT_DIR` set to it, assert the notice is emitted
- [ ] Confirm it fails (red)
- [ ] Apply step 1
- [ ] Confirm it passes (green)
- [ ] Assert a fixture with only `.claude/settings.local.json` and `.mallet/` emits nothing
- [ ] Assert the payload-pair predicate fires when `framework.json` is absent but both `skills/update/SKILL.md` and `agents/_contract.md` are present
- [ ] Assert creating `.mallet/.migration-declined` suppresses the notice
- [ ] Assert the hook still exits 0 when `CLAUDE_PROJECT_DIR` is unset
- [ ] Regression: project memory injection and the update check still behave as before

## Notes
The notice instructs Claude rather than the user directly, matching the existing `--- Framework Update Available ---` block's style at `session-start.sh:46`.
