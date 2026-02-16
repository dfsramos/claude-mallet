# Skills

Skills are reusable capabilities defined as `SKILL.md` files inside `.claude/skills/`. Each skill lives in its own subdirectory and is automatically available to Claude Code when the project is opened.

## Session Wrap-Up

**Directory:** `.claude/skills/reviewing-sessions/`
**Triggered by:** Phrases like "wrap up", "all done", or "end session"

A structured end-of-session retrospective that produces:

1. **Session summary** — goal, approach, outcome
2. **What went well** — efficient tasks, effective patterns, good tool use
3. **What went poorly** — mistakes, user corrections, rule violations (with specific references)
4. **Applied improvements** — updates to skills or directives based on session observations
5. **Session record** — saved to `.claude/sessions/<session-id>.md`

## Skill Backlog

**File:** `.claude/skill-backlog.md` (created on demand)

During any session, Claude silently logs observations about potential new skills or improvements to existing ones. Items are appended to this file without interrupting the workflow. The user reviews and promotes entries at their own pace.

## Adding New Skills

1. Create a subdirectory under `.claude/skills/` with a descriptive name
2. Add a `SKILL.md` file defining the skill's purpose, trigger conditions, steps, and allowed tools
3. Claude Code will pick up the skill automatically
