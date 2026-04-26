---
name: implement-feature
description: Invoke when the user asks to implement a feature, add functionality, or make a non-trivial code change. Orchestrates the full pipeline: spec → plan → critique → implement → test → review → validate.
---

# Implement Feature

Orchestrates a structured, context-isolated pipeline for implementing features. Each step runs in a subagent — the main session only sees distilled outputs and makes routing decisions.

---

## 0. Pre-flight

Read `.claude/agents/_contract.md`. All subagents must return output in that contract format.

**Check for an existing pipeline state file first.** Run:
```bash
ls .claude/pipeline-state/ 2>/dev/null
```
If a state file exists, ask the user: "I found an in-progress pipeline for `<slug>` (last completed: step N — <agent name>). Resume it, or start fresh?"

- Resume → skip to [Resume](#resume) section at the bottom
- Fresh → continue below

**Collect from the user (if not already provided):**
- Feature description (required)
- Test command (required — e.g. `dotnet test ./Solution.sln`, `pytest`, `npm test`)
- Working directory (default: current project root)

Do not proceed until you have all three.

**Generate a slug** from the feature description: lowercase, hyphenated, max 5 words. Confirm with the user in one line: `Slug: implement-user-notifications — ok?`

**Ask the following yes/no questions in a single message**, presented as a numbered list. Wait for the user to answer all of them before continuing.

> Before I start, a few quick questions:
> 1. Run a **plan critique** after the change plan is drafted? (Challenges the plan before any code is written)
> 2. Run a **code review** after implementation? (Senior-developer review of the diff)
> 3. Run a **scope validation** at the end? (Verifies all acceptance criteria are met and no scope creep)

Record the answers and skip the corresponding steps (3, 6, 7) if the user answers no.

**Initialise the state file** at `.claude/pipeline-state/<slug>.md`:

```markdown
# Pipeline: <slug>
started: YYYY-MM-DD
feature: <description>
working_dir: <path>
test_command: <command>
settings:
  critique: yes|no
  review: yes|no
  scope_validation: yes|no

## Current Step
0 (pre-flight)

## Run Log
| Step | Agent | Status | Iterations | Note |
|------|-------|--------|------------|------|

## Completed Handoffs
<!-- Populated as steps complete -->
```

Create the `.claude/pipeline-state/` directory if it does not exist.

---

## State Checkpoint

After **every step completes with `approve`**, update the state file:

1. Advance `## Current Step` to the next step number and name
2. Append a row to `## Run Log`: step number, agent name, status, iteration count, any note (blocker hit, revision reason)
3. Append the agent's Handoff output under `## Completed Handoffs` as a named section (e.g. `### Step 1 Handoff — Frida`)

Do this before spawning the next subagent. If the session ends between steps, the state file captures exactly where to resume.

---

## 1. Feature Analysis

Spawn `feature-analyst` subagent (Frida) using `.claude/agents/feature-analyst.md`:
- Pass: feature description + any available project context (README, CLAUDE.md excerpt, relevant file list)
- Model: sonnet

On return:
- `approve` → checkpoint state, proceed to step 2 with the Handoff section
- `blocked` → surface the Unknowns list to the user, wait for answers, re-run step 1

---

## 2. Code Analysis

Before spawning: identify candidate files using grep/find based on the spec's scope. Pass file paths — not file contents — to the subagent, and let it read what it needs.

Spawn `code-analyst` subagent (Callum) using `.claude/agents/code-analyst.md`:
- Pass: feature spec Handoff + list of candidate file paths + working directory
- Model: sonnet
- Iteration cap: 2

On return:
- `approve` → checkpoint state, proceed to step 3 with the Handoff section
- `revise` → re-run with Amendments appended to the prompt (max 2 iterations, then `blocked`)
- `blocked` → surface to user

---

## 3. Plan Critique

Spawn `plan-critic` subagent (Percy) using `.claude/agents/plan-critic.md`:
- Pass: feature spec Handoff + change plan Handoff
- Model: sonnet
- Iteration cap: 2 (across steps 2–3 combined)

On return:
- `approve` → checkpoint state, proceed to step 4
- `revise` → return to step 2 with critic Amendments appended (counts against step 2's iteration cap)
- `blocked` → surface to user

---

## 4. Implementation

Spawn `implementer` subagent (Ingrid) using `.claude/agents/implementer.md`:
- Pass: approved change plan Handoff + working directory
- Model: sonnet
- Iteration cap: 2 (across steps 4–5 combined)

On return:
- `approve` → checkpoint state, proceed to step 5
- `blocked` → surface to user

---

## 5. Test

Spawn `test-runner` subagent (Tobias) using `.claude/agents/test-runner.md`:
- Pass: test command + working directory + changed files list (from implementer Handoff)
- Model: haiku

On return:
- `approve` → checkpoint state, proceed to step 6
- `revise` → return to step 4 (Ingrid) with test-runner Failures Handoff appended (counts against step 4's iteration cap)
- `blocked` → surface to user — likely a build or environment issue

---

## 6. Code Review

Spawn `code-reviewer` subagent (Clifford) using `.claude/agents/code-reviewer.md`:
- Pass: list of changed files + working directory
- Model: sonnet
- Iteration cap: 1 (one revision cycle only)

On return:
- `approve` → checkpoint state, proceed to step 7
- `revise` → return to step 4 (Ingrid) with blocking issues Handoff appended (counts against step 4's iteration cap)
- `blocked` → surface to user

---

## 7. Scope Validation

Spawn `scope-validator` subagent (Sylvie) using `.claude/agents/scope-validator.md`:
- Pass: original feature spec Handoff + changed files list + working directory + reviewer non-blocking notes (if step 6 ran)
- Model: sonnet

On return:
- `approve` → checkpoint state, proceed to wrap-up
- `revise` → surface specific gaps to user and ask whether to re-enter the pipeline at step 2 or 4

---

## 8. Wrap-up

Read the completed state file. Surface the run log to the main session:

```
Pipeline complete: <slug>
──────────────────────────────────────────
Step 1  Frida     approve   1 iteration
Step 2  Callum    approve   2 iterations  (1 revision from Percy)
Step 3  Percy     approve   1 iteration
Step 4  Ingrid    approve   1 iteration
Step 5  Tobias    approve   2 iterations  (1 test fix)
Step 6  Clifford  approve   1 iteration   2 non-blocking notes
Step 7  Sylvie    approve   1 iteration
──────────────────────────────────────────
Files changed: [list]
Tests: 47 passed, 0 failed
Non-blocking review notes:
  - [note from Clifford, if any]
```

This run log is what the `reviewing-sessions` wrap-up skill uses for its "What Went Well/Poorly" and token efficiency sections.

Delete the state file on successful completion:
```bash
rm .claude/pipeline-state/<slug>.md
```

Offer: "Want me to open a PR?"

---

## Iteration Budget Reference

| Step | Cap | What resets it |
|------|-----|---------------|
| Feature analysis (1) | unlimited | Only blocks on missing user input |
| Code analysis (2) + critique (3) | 2 combined | User resolves a blocker — note: if Percy's second revise contains only small, concrete amendments (single-line fixes, missing guards), prefer folding them into Ingrid's prompt rather than blocking; surface to user with that option |
| Implementation (4) + tests (5) + review (6) | 2 combined | User resolves a blocker |
| Scope validation (7) | 1 | Re-entering pipeline resets budget |

When a cap is hit: set status `blocked`, surface to user with the last revision request, and wait for direction.

---

## Resume

Read the state file for the slug the user confirmed. Extract:
- `## Current Step` — the step to resume from
- `## Completed Handoffs` — prior agent outputs to pass forward
- `settings` — which optional steps are enabled

Re-enter the pipeline at the indicated step, passing the relevant Handoffs as if the prior steps had just completed. The iteration budget resets for the resumed step's group.
