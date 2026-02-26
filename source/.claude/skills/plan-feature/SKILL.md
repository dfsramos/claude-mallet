---
name: plan-feature
description: Plans and executes a feature from high-level description through implementation. Invoke when the user wants to plan a new feature, build something, or continue work on an existing feature plan.
---
# Feature Planning

## Setup

Open a worktree on master to read and write planning files without disrupting the current branch:

```bash
git worktree list | grep -q /tmp/feature-planning || git worktree add /tmp/feature-planning master
git -C /tmp/feature-planning pull --ff-only
```

Cleanup on completion or error: `git worktree remove --force /tmp/feature-planning`

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

Create a stub `tasks/NN-<name>.md` for each task:

```markdown
# Task: <name>
Status: pending
Deps: <list or —>

## Goal

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

For each iteration:

1. Identify next task(s): all whose dependencies are marked `done`
2. If multiple can run in parallel, ask: proceed in parallel or sequentially?
3. For each task: read its task file, ask any remaining narrow questions, then execute
4. **Autonomy rules:**
   - Local / git-tracked work: proceed freely
   - Remote servers or production databases: confirm writes and deletes before executing; reads are free
5. After a task completes: mark `done` in the task file and in `plan.md`, commit both via the master worktree

When all tasks are done: set feature `Status: done`, commit, remove worktree.

---

## Resume

If the user references an existing feature, load its `plan.md` from the master worktree, identify incomplete tasks, and proceed from step 4 — skip intake and decomposition.
