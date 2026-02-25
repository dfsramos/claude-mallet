---
name: reviewing-sessions
description: Performs a structured end-of-session retrospective. Invokes when the user agrees to a session wrap-up, or uses phrases like "wrap up", "all done", or "end session". Produces a retrospective report, applies skill and directive improvements, processes the skill backlog, and saves a session record keyed to the session ID.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---
# Session Wrap-Up

Read the session ID from `.claude/sessions/.current` or the `$SESSION_ID` environment variable. All output from this process references that ID.

---

## 1. Session Summary

Write a concise summary of what was accomplished this session: the starting problem or goal, the approach taken, and the outcome.

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
- Rules from CLAUDE.md that were not followed correctly

Be specific. Reference the actual exchange, not a generalisation.

---

## 4. Skill and Directive Improvements

Based on what went poorly and what was learned:

- **Update existing skills**: fix missing commands, outdated instructions, or unclear steps that caused issues during the session. Apply the changes — do not just list them.
- **Create new skills**: if a knowledge gap came up repeatedly or a new reusable pattern emerged, create the skill file now at `.claude/skills/<skill-name>/SKILL.md`.
- **Update CLAUDE.md**: if a behavioural rule was missing, ambiguous, or not followed correctly, fix it at `CLAUDE.md` at the project root directly.

If any changes were made to framework files with corresponding docs (`docs/`), verify those docs are up to date before considering the work complete. Check that new features have dedicated sections, tables are updated, and examples reflect the current behaviour.

Then open `.claude/skill-backlog.md`. For each item logged during this session:
- Evaluate whether it is still relevant given what was actually done
- If yes, action it: create the skill or apply the improvement
- Remove actioned items from the backlog
- Leave items that need more context or a future session

---

## 4a. Review Memory Entries

If `.claude/project/memory.md` exists, open it. For any entries added or modified during this session:
- Confirm they are accurate based on what was actually observed
- Rewrite any that are vague or poorly phrased
- Remove any that turned out to be wrong or are already covered by CLAUDE.md or a skill

Do not add new entries here unless something significant was missed during the session.

---

## 5. Save Session Record

Create a file at `.claude/sessions/<session-id>.md` inside the current project directory. If the `.claude/sessions/` directory does not exist, create it.

The file should contain:

```markdown
# Session: <session-id>
Date: YYYY-MM-DD HH:MM

## Summary
<one to three sentences>

## What Went Well
<bullet points>

## What Went Poorly
<bullet points>

## Changes Made
- Skills created: <list or "none">
- Skills updated: <list or "none">
- CLAUDE.md changes: <description or "none">
- Skill backlog items actioned: <list or "none">
```

Do not append to a shared log. Each session gets its own file, retrievable by its ID.

---

## 6. Start Next Session

Generate a new session ID for the next task by running the session-start hook. **Do not run this hook at any other point during the session** — it overwrites `.claude/sessions/.current`, displacing the session ID in use.

```bash
CLAUDE_PROJECT_DIR=$(pwd) bash .claude/hooks/session-start.sh
```

This ensures each task within a conversation gets its own unique session ID.
