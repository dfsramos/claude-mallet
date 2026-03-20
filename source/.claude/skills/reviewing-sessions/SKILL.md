---
name: reviewing-sessions
description: Invoke when the user agrees to a session wrap-up, or says "wrap up", "all done", "end session", or similar. Also when the user proactively asks for a session summary or retrospective.
---
# Session Wrap-Up

The session ID is available as the `$SESSION_ID` environment variable (injected at session start). Reference it in the wrap-up output.

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

