---
name: plan-feature
description: Invoke when the user wants to plan a new feature, build something new, or continue work on an existing feature plan.
allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/plans-worktree.sh)
---
# Feature Planning

## Setup

Feature plans live in `.mallet/features/` on the default branch so they're visible across branches. Resolve where to write them:

```bash
bash ${CLAUDE_SKILL_DIR}/plans-worktree.sh
```

It prints `DEFAULT=<branch>`, `PLANS_DIR=<path>`, and `COMMIT=yes|no`. Below, `<plans>` means `PLANS_DIR`.

- On the default branch, `<plans>` is the current checkout.
- On any other branch, `<plans>` is a worktree of the default branch that belongs to this repository alone (inside its `.git` directory, or an existing worktree that already has the default branch). Leave it in place between sessions; it is reused.
- `COMMIT=no` means `.mallet/` is ignored in this repository — the user's choice not to track it. Write plans in `<plans>` and skip every commit step below; say so once.
- If the script fails, report its error and stop. Do not fall back to a hand-made worktree.

Every commit below names its paths, so nothing else staged in `<plans>` is swept in: `git -C <plans> commit -m "<message>" -- .mallet/features/<slug>/`.

---

## 1. Pre-Check

Read all `plan.md` files under `<plans>/.mallet/features/`. If any overlap with what the user is describing, surface them and ask: extend an existing feature or create a new one?

---

## 2. Intake (new features only)

Ask 3–5 broad questions:
- What problem does it solve?
- Who uses it and how?
- What does success look like?
- Any constraints (technical, scope, timeline)?
- Does it touch remote systems or production data?

Follow up with targeted questions where the picture is still incomplete. Stop when you have enough to decompose.

---

## 2a. Design Approval Gate

Before decomposing into tasks, present a one-paragraph design summary to the user:

> **Proposed design:** [what will be built, how it fits the existing system, key tradeoffs]
>
> Does this match your intent, or should we adjust before I break it into tasks?

When the design commits to something expensive to reverse — a data model, a framework or vendor, a public API, removing a capability — also offer to test it with `/mallet:council` before approval, and run it once the user agrees.

Do not proceed to decomposition until the user explicitly approves. Rationalizations to reject:
- "The intake was thorough so we can proceed" — intake gathers facts; the design summary is the synthesis that can still be wrong
- "I'll adjust during implementation if needed" — misaligned decomposition produces misaligned tasks; a one-sentence correction now saves N task rewrites later

---

## 2b. Assess Knowledge Skill Opportunity

After intake, check whether the feature operates in a domain with strong, stable conventions where encoding expertise as a knowledge skill would improve implementation quality.

Signals — the feature touches API design, auth flows, data modelling, security-sensitive logic (payments/PII/compliance), accessibility, performance-critical paths, or domain-specific rules (healthcare, legal, finance).

If any signals are present, ask: "This feature touches [domain] — would a knowledge skill help guide implementation? I can scaffold one alongside the plan."

If yes:
- Copy `${CLAUDE_SKILL_DIR}/knowledge-skill-template.md` to `.mallet/skills/<domain>-knowledge/SKILL.md`
- Fill in what is already known from intake; leave the rest as placeholders
- Note the skill in `plan.md` under a **Supporting Skills** section

---

## 3. Decompose

Confirm a slug with the user (lowercase, hyphenated).

Create `<plans>/.mallet/features/<slug>/plan.md`:

```markdown
# Feature: <name>
Status: planning
Created: YYYY-MM-DD
Branch: —

## Goal
<one sentence>

## Context
<2–3 sentences>

## Tasks
- [ ] 01-<name> — <description> [deps: —] [parallel: yes/no]
- [ ] 02-<name> — <description> [deps: 01] [parallel: yes/no]
```

Create `<plans>/.mallet/features/<slug>/state.md`:

```markdown
# State: <feature-name>

## Decisions
<!-- YYYY-MM-DD: <decision> — <reasoning> -->

## Blockers
<!-- - [ ] <description> (check off when resolved) -->
```

Create a stub `tasks/NN-<name>.md` for each task:

```markdown
# Task: <name>
Status: pending
Deps: <list or —>

## Goal

## Steps
<!-- No TBD, no placeholders. Each step must be a concrete action: exact file path, specific command, precise code change. If a step cannot be written concretely, the design is underspecified — resolve that before writing the task. -->

## TDD Checklist
_(Omit if the task has no testable behaviour.)_
- [ ] Write failing test
- [ ] Confirm test fails (red)
- [ ] Implement
- [ ] Confirm test passes (green)
- [ ] Confirm no regressions

## Notes
```

**Task content discipline:** before committing any task file, verify:
- Every step names a specific file path or command — no "update the relevant file"
- No step contains TBD, TODO, or "as appropriate"
- The TDD checklist is present for any task with testable behaviour
- The goal is one sentence that could be copy-pasted into a commit message

Commit to the default branch (skip when `COMMIT=no`):

```bash
git -C <plans> add .mallet/features/<slug>/
git -C <plans> commit -m "Add feature plan: <slug>." -- .mallet/features/<slug>/
```

---

## 4. Execute

Create the feature branch from the default branch, following the persona's branch naming: `git checkout -b f/<slug> <DEFAULT>` (`b/<slug>` for a bug fix). Update the Branch field in `plan.md` and commit it in `<plans>`.

For each wave:

1. **Identify the wave:** collect all tasks whose dependencies are all marked `done`
2. **Present the wave:** if it contains multiple tasks flagged `[parallel: yes]`, ask: run in parallel or sequentially?
3. **Execute the wave:**
   - *Sequential:* for each task, read its task file, ask any remaining narrow questions, then execute.
   - *Parallel:* dispatch each task to its own subagent (one tool call per task, all in a single message). Each subagent reads its task file and executes autonomously; only results surface to the main context.
   - Parallel only when tasks are genuinely independent — no shared files, no sequential dependencies, no mid-task interactive decisions. Otherwise run sequentially.
4. **Autonomy:** follow base `CLAUDE.md` — Destructive Operations and Production Awareness apply.
5. **After each task completes:** mark `done` in the task file and in `plan.md`, commit both in `<plans>`; log any decisions made or blockers encountered to `state.md`
6. **After the wave completes:** reassess — identify the next wave and repeat

When all tasks are done: set feature `Status: done` and commit in `<plans>`. The plans worktree stays for the next feature; remove it only if the user asks (`git worktree remove <plans>`, which refuses if it has uncommitted changes).

---

## Resume

If the user references an existing feature, run the Setup script, then load its `plan.md` and `state.md` from `<plans>`. Read `state.md` first — it captures decisions made and open blockers from prior sessions. Identify incomplete tasks and proceed from step 4 — skip intake and decomposition.
