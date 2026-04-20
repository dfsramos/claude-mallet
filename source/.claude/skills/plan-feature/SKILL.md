---
name: plan-feature
description: Invoke when the user wants to plan a new feature, build something new, or continue work on an existing feature plan.
---
# Feature Planning

## Setup

Feature plans live in `.claude/features/` on master so they're visible across branches.

- **If already on master**: work in the current directory. No worktree needed.
- **Otherwise**: open a master worktree:

```bash
git worktree list | grep -q /tmp/feature-planning || git worktree add /tmp/feature-planning master
git -C /tmp/feature-planning pull --ff-only
```

Cleanup on completion: `git worktree remove --force /tmp/feature-planning`.

Below, paths prefixed `/tmp/feature-planning/` apply to the worktree case — drop the prefix when working directly on master, and use plain `git` instead of `git -C /tmp/feature-planning`.

---

## 1. Pre-Check

Read all `plan.md` files under `/tmp/feature-planning/.claude/features/`. If any overlap with what the user is describing, surface them and ask: extend an existing feature or create a new one?

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

## 2b. Assess Knowledge Skill Opportunity

After intake, check whether the feature operates in a domain with strong, stable conventions where encoding expertise as a knowledge skill would improve implementation quality.

Signals — the feature touches API design, auth flows, data modelling, security-sensitive logic (payments/PII/compliance), accessibility, performance-critical paths, or domain-specific rules (healthcare, legal, finance).

If any signals are present, ask: "This feature touches [domain] — would a knowledge skill help guide implementation? I can scaffold one alongside the plan."

If yes:
- Copy `.claude/templates/knowledge-skill/SKILL.md` to `.claude/project/skills/<domain>-knowledge/SKILL.md`
- Fill in what is already known from intake; leave the rest as placeholders
- Note the skill in `plan.md` under a **Supporting Skills** section

---

## 3. Decompose

Confirm a slug with the user (lowercase, hyphenated).

Create `/tmp/feature-planning/.claude/features/<slug>/plan.md`:

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

Create `/tmp/feature-planning/.claude/features/<slug>/state.md`:

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

## TDD Checklist
_(Omit if the task has no testable behaviour.)_
- [ ] Write failing test
- [ ] Confirm test fails (red)
- [ ] Implement
- [ ] Confirm test passes (green)
- [ ] Confirm no regressions

## Notes
```

Commit to master:

```bash
git -C /tmp/feature-planning add .claude/features/<slug>/
git -C /tmp/feature-planning commit -m "Add feature plan: <slug>."
```



---

## 4. Execute

Create a feature branch off master: `git checkout -b <slug>`. Update the Branch field in `plan.md` and commit via the master worktree.

For each wave:

1. **Identify the wave:** collect all tasks whose dependencies are all marked `done`
2. **Present the wave:** if it contains multiple tasks flagged `[parallel: yes]`, ask: run in parallel or sequentially?
3. **Execute the wave:**
   - *Sequential:* for each task, read its task file, ask any remaining narrow questions, then execute.
   - *Parallel:* dispatch each task to its own subagent (one tool call per task, all in a single message). Each subagent reads its task file and executes autonomously; only results surface to the main context.
   - Parallel only when tasks are genuinely independent — no shared files, no sequential dependencies, no mid-task interactive decisions. Otherwise run sequentially.
4. **Autonomy:** follow base `CLAUDE.md` — Destructive Operations and Production Awareness apply.
5. **After each task completes:** mark `done` in the task file and in `plan.md`, commit both via the master worktree; log any decisions made or blockers encountered to `state.md`
6. **After the wave completes:** reassess — identify the next wave and repeat

When all tasks are done: set feature `Status: done`, commit, remove worktree.

---

## Resume

If the user references an existing feature, load its `plan.md` and `state.md` from the master worktree. Read `state.md` first — it captures decisions made and open blockers from prior sessions. Identify incomplete tasks and proceed from step 4 — skip intake and decomposition.
