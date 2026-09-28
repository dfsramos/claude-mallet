---
name: checkpoint
description: Invoke when the user says "checkpoint", "save state", "/checkpoint", or asks to save progress mid-session. Also invoke proactively when a session is running long and compaction feels imminent — run this before /compact so key state survives.
---
# Checkpoint

Persist the session's in-progress state to disk so it survives compaction or a restart. No summary, no reflection — that's reviewing-sessions' job. This skill only writes.

---

## 1. Memory

Use Claude Code's auto memory, not a Mallet file. Save anything from this session that is not yet recorded:
- corrections from the user, as `feedback` memories carrying the why and how to apply
- non-obvious commands, confirmed conventions, tool quirks, environment gotchas, as `project` or `reference` memories

Update an existing memory rather than adding a duplicate. Do not save anything already covered by CLAUDE.md or a skill, or session-specific state (current branch, task list, in-progress work — that belongs in the mission file).

Skip if nothing new to record.

---

## 2. Mission State

Assess whether this session's work is part of an ongoing mission that will need to continue.

**If work is clearly ongoing** (multi-step task not yet complete):
- Read `.mallet/missions/active.md` first if it exists. If it holds a *different* mission that is still open, do not overwrite it — write this session's mission to `.mallet/missions/<short-name>.md` instead and tell the user both are live so they can decide which is active. This is not hypothetical: a checkpoint run has already attempted exactly that overwrite against a mission holding thirteen open items, and only the `write-guard` hook refusing `Write` on an existing file stopped it.
- Otherwise write or overwrite `.mallet/missions/active.md` with the current state:

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

## 3. Confirm

Report in one line per file what was written, e.g.:

```
Checkpoint complete: memory (+1 feedback), missions/active.md (updated)
```

If nothing was written anywhere: `Checkpoint: nothing new to persist.`
