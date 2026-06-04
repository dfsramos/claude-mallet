# Project Discovery Report
Date: 2026-06-04
Project: claude-mallet

## Overview

Claude Mallet is a portable Claude Code configuration framework — not an application. Its "stack" is bash, markdown, and JSON. External dependencies: `curl`, `jq`, `gh`. No build tooling, no test framework, no package manager.

The audit covers: skill coherence, hook correctness, CLAUDE.md directive accuracy, docs parity, and cross-file consistency.

---

## Critical Gaps

### 1. `reviewing-sessions` is missing a close-out step

**What happened:** The f/mission-continuity branch replaced the old "## 5. Close Out" with new steps 5 (Save Session Record) and 6 (Start Next Session). Step 4b (Mission State) was merged; steps 5 and 6 were not (correctly excluded due to project CLAUDE.md prohibiting session record files). But the original "## 5. Close Out" was also deleted — and was not restored.

**Effect:** The skill ends at step 4b with no finalization. There is no instruction to:
- Present the completed wrap-up to the user
- Clear `.claude/project/task-notes.md` if it was used
- Confirm the working branch is correct after a session that may have involved worktrees

**Fix needed:** Restore a close-out step (either the old one, or a revised version appropriate for the current skill structure).

---

### 2. CLAUDE.md references `$SESSION_ID` and `.claude/sessions/` — neither exists

`CLAUDE.md` says:
> "Each session has a unique ID injected into context at startup as `$SESSION_ID`."

And:
> "Do not read `.claude/sessions/` files at session start or proactively."

The session-start hook does not inject `$SESSION_ID`. No `.claude/sessions/` directory exists or is created by any skill or hook. These are dead references, likely left over from an earlier design that was partially backed out.

**Fix needed:** Remove both dead references from CLAUDE.md.

---

## Docs Parity Gaps

### 3. `docs/structure.md` is stale

The hooks listing shows only `session-start.sh` and `user-prompt-submit.sh`. Missing:
- `write-guard.sh` (default, blocking)
- `typecheck.sh` (optional tier)
- `push-confirm.sh` (optional tier)

The skills listing is also incomplete — missing: `dispatching-parallel-agents`, `hooks-setup`, `receiving-code-review`, `preflight`.

The project directory tree doesn't show `missions/` under `.claude/project/`.

The `pipeline-state/` directory created by `implement-feature` appears nowhere in docs.

### 4. `docs/skills.md` reviewing-sessions description is misleading

States: *"Wrap-ups are conversational only — no files are written to disk."*

This is only half-true: wrap-up step 4 explicitly writes to skill files and CLAUDE.md. What the phrase means is "no session *record* file is created" — but as written it reads as "nothing is written at all", which contradicts the skill.

The description also stops at step 4b and doesn't reflect that there is no close-out step (gap 1 above).

---

## Minor Coherence Issues

### 5. Skill description field in reviewing-sessions doesn't mention mission state

The `description:` frontmatter says: *"Invoke when the user agrees to a session wrap-up, or says 'wrap up', 'all done', 'end session', or similar."*

Fine as-is — trigger conditions only, which is correct per skill authoring rules. No change needed.

### 6. `docs/skills.md` reviewing-sessions says "no files written" while step 4 writes files

Covered by gap 4 above — the doc phrase is scoped to session *records*, but the wording doesn't communicate that. A one-word fix ("no session record files") resolves it.

### 7. `framework.json` was absent until today

Just created this session. The update check and statusline both read it; prior to today neither worked in this repo. Now resolved.

---

## Things That Are Correct and Coherent

- Hook invocations all use `bash "..."` explicitly — consistent with both the hooks-layer rationale and the docs explanation.
- install/update flows correctly preserve `.claude/project/**` and `.claude/settings.local.json`; correctly overwrite all framework-managed paths.
- `dispatching-parallel-agents` trigger threshold (3+ domains) is documented consistently in the skill and README.
- `implement-feature` pipeline state files are scoped to `.claude/pipeline-state/` which is in `.gitignore` — correct.
- Agent _contract.md is clear and referenced correctly by the orchestrator skill.
- `plan-feature` worktree usage is sound: features are committed to master via worktree so they're visible across branches.
- Project CLAUDE.md overrides are well-structured: the git workflow override is specific, the sessions-file prohibition has a corresponding lessons.md entry.
- `write-guard.sh` correctly exits 2 to block and exits 0 to allow; rationale (exit 0 for advisory) is correctly used for `push-confirm.sh`.
- `hooks-setup` idempotency logic is correct: checks by script filename presence before appending.

---

## Recommended Actions (Priority Order)

**High — fix now:**
1. Restore a close-out step to `reviewing-sessions` (step 5: present wrap-up, clear task-notes if used, confirm branch)
2. Remove `$SESSION_ID` and `.claude/sessions/` dead references from CLAUDE.md

**Medium — docs parity:**
3. Update `docs/structure.md`: add missing hooks, skills, `missions/`, `pipeline-state/`
4. Fix the "no files written" wording in `docs/skills.md` reviewing-sessions entry

---

## Promotable to Framework

Nothing new emerged this session. The `framework.json` bootstrapping pattern (for self-hosting) is specific to the framework repo itself, not a general pattern.
