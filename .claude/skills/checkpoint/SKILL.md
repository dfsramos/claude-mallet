---
name: checkpoint
description: Invoke when the user says "checkpoint", "save state", "/checkpoint", or asks to save progress mid-session. Also invoke proactively when a session is running long and compaction feels imminent — run this before /compact so key state survives.
---
# Checkpoint

Persist the session's in-progress state to disk so it survives compaction or a restart. No summary, no reflection — that's reviewing-sessions' job. This skill only writes.

---

## 1. Lessons

Open `.claude/project/lessons.md`. Append any corrections or rules that emerged during this session and have not already been recorded. Use the standard format:

```
## YYYY-MM-DD — <short title>
**What went wrong:** ...
**Rule:** ...
```

Skip if nothing new to record.

---

## 2. Memory

If `.claude/project/memory.md` exists, open it. Add any new facts discovered this session that belong in persistent memory: non-obvious commands, confirmed conventions, tool quirks, environment gotchas.

Do not add anything already covered by CLAUDE.md or a skill, and do not add session-specific state (current branch, task list, in-progress work — that belongs in the mission file).

Skip if nothing new to record.

---

## 3. Mission State

Assess whether this session's work is part of an ongoing mission that will need to continue.

**If work is clearly ongoing** (multi-step task not yet complete):
- Write or overwrite `.claude/project/missions/active.md` with the current state:

```markdown
# Mission: <name>
session: <current-session-id>
started: YYYY-MM-DD
project: <project or repo name>

## Goal
<1-2 sentences>

## Completed
- [x] <task> _(session: <id>)_

## Pending
- [ ] <task>

## Blocked
<describe blockers, or remove section>

## Decisions
- **<decision>** — <rationale> `[firm|tentative]`
```

Each pending task must be self-contained — the next session reads this cold.

**If work is single-session or already complete**: skip this step.

---

## 4. Confirm

Report in one line per file what was written, e.g.:

```
Checkpoint complete: lessons.md (+1), missions/active.md (updated)
```

If nothing was written anywhere: `Checkpoint: nothing new to persist.`
