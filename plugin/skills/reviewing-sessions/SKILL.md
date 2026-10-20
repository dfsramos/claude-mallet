---
name: reviewing-sessions
description: Invoke when the user agrees to a session wrap-up, or says "wrap up", "all done", "end session", or similar. Also when the user proactively asks for a session summary or retrospective.
---
# Session Wrap-Up

---

## 1. Session Summary

Present a concise summary of what was accomplished this session: the starting problem or goal, the approach taken, and the outcome. Output to the conversation only — do not write to a file.

---

## 2. What Went Well

Review the session and identify:
- Tasks that were completed efficiently and without correction
- Approaches or patterns that worked and are worth repeating
- Effective use of tools, skills, or commands
- Moments where evidence-based reasoning led to a quick resolution

---

## 3. What Went Poorly

Review the session and identify:
- Mistakes, misunderstandings, or incorrect assumptions made
- Cases where the user had to correct course or reject a tool call
- Unnecessary back-and-forth that could have been avoided
- Directives from the persona, `CLAUDE.md`, or `.claude/rules/` that were not followed correctly

Be specific. Reference the actual exchange, not a generalisation.

---

## 3a. Token Efficiency

Note any patterns that drove unnecessary token use this session:

- Long session without a `/compact` — flag in "What Went Poorly"
- Write used on an existing file (should have been Edit) — adds ~2× the output tokens per operation
- Verbose response written after a routine Bash command (summarising output, writing unsolicited plans)
- Subagent calls on a stronger model than the work needed (file reads, grep, lookups)

If any of these occurred and no directive or memory already covers it, save a `feedback` memory for it.

---

## 4. Skill and Directive Improvements

Based on what went poorly and what was learned:

- **Fix skills that caused issues** — missing commands, outdated instructions, unclear steps. Where the fix goes depends on whose skill it is:
  - A project skill (`.claude/skills/`, or `.mallet/skills/` from an earlier Mallet version) or a personal one (`~/.claude/skills/`): edit it directly.
  - A Mallet skill (`/mallet:<name>`): never edit its files. They live in the plugin cache and the next update overwrites them. Propose the amendment to the user as a project rule and, on agreement, write it to `.claude/rules/<name>.md` as "When running `/mallet:<name>`, ..." lines; Claude Code loads that file in every session. If the fix would help every project, also describe it to the user as a proposed change to Mallet itself.
- **Create new skills**: if a knowledge gap came up repeatedly or a new reusable pattern emerged, create the skill file now. Project-specific skills go to `.claude/skills/<skill-name>/SKILL.md`, which Claude Code discovers itself; skills useful across every project go to `~/.claude/skills/<skill-name>/SKILL.md`. When unsure, prefer project-specific — promoting later is cheap, and a half-general personal skill applies everywhere.
- **Fix missing or unclear rules**: a rule for this project belongs in `.claude/rules/<topic>.md` or `CLAUDE.md`. Both are usually tracked and shared with a team, so propose the exact text to the user and write it only on agreement. A rule for every project is a `feedback` memory.

Apply the changes — do not just list them.

If `.mallet/skill-backlog.md` exists (earlier Mallet versions logged skill ideas there), go through it: action what is still relevant, remove each actioned or stale item, and delete the file once it is empty.

---

## 4a. Review Memory Entries

Review the auto memory entries written or updated during this session:
- Confirm they are accurate based on what was actually observed
- Rewrite any that are vague or poorly phrased
- Delete any that turned out to be wrong or are already covered by CLAUDE.md or a skill
- Save any user correction from this session that is not yet a `feedback` memory

Do not add new entries here unless something significant was missed during the session.

---

## 4b. Mission State

Assess whether work from this session is part of a larger mission that will continue in a future session.

**If the mission is complete** (all tasks done, goal achieved):
- If `.mallet/missions/active.md` exists, read it, write the contents to `.mallet/missions/archive/<session-id>.md`, then delete the original.

**If work is ongoing** (3+ steps total, or clearly unfinished):
- Read `.mallet/missions/active.md` first if it exists. If it holds a *different* mission that is still open, do not overwrite it. Either consolidate the two deliberately, or leave this session's mission in its own `.mallet/missions/<short-name>.md` and cross-reference them, then tell the user which you did. Two concurrent missions is a normal state that a single `active.md` does not model well.
- Otherwise write or update `.mallet/missions/active.md` using the format below, overwriting rather than appending.

```markdown
# Mission: <name>
session: <current-session-id>
started: YYYY-MM-DD
project: <project or repo name>

## Goal
<1-2 sentences — what are we building and why>

## Completed
- [x] <task> _(session: <id>)_

## Pending
- [ ] <task>

## Blocked
<describe blockers, or remove this section if none>

## Decisions
- **<decision>** — <rationale> `[firm]`
- **<decision>** — <rationale> `[tentative]`
```

Keep entries terse. The next session reads this cold — each pending task must be self-contained enough to act on without re-reading code.

**If work was single-session with no continuation expected**: skip this step entirely.

---

## 5. Close Out

- Confirm you are on the correct working branch (not a feature branch left over from this session).
- Present the completed wrap-up (sections 1–4b) to the user as a single formatted response.

