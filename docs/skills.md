# Skills

Skills are reusable capabilities defined as `SKILL.md` files inside `.claude/skills/`. Each skill lives in its own subdirectory and is automatically available to Claude Code when the project is opened.

## Project Discovery

**Directory:** `.claude/skills/discover/`
**Triggered by:** `/discover`, or phrases like "discover this project" or "analyze the codebase"

A structured analysis of a project's codebase to identify opportunities for improving the `.claude/` setup. The skill runs interactively and produces:

1. **Initial scan** — languages, frameworks, build tools, project structure
2. **External service detection** — API clients, SDKs, auth providers, data services
3. **Skill opportunities** — repeatable patterns that could become skills (deployments, DB ops, testing)
4. **Connection data** — services and systems that should have connection templates documented
5. **Project conventions** — patterns worth capturing in `.claude/project/CLAUDE.md`
6. **Promotable patterns** — generic enough to move into the base framework
7. **Discovery report** — saved to `.claude/discovery-YYYY-MM-DD.md`
8. **Quick wins** — offer to immediately implement high-value stub skills or conventions

## Session Wrap-Up

**Directory:** `.claude/skills/reviewing-sessions/`
**Triggered by:** Phrases like "wrap up", "all done", or "end session"

A structured end-of-session retrospective that produces:

1. **Session summary** — goal, approach, outcome
2. **What went well** — efficient tasks, effective patterns, good tool use
3. **What went poorly** — mistakes, user corrections, rule violations (with specific references)
4. **Applied improvements** — updates to skills or directives based on session observations; skill backlog reviewed and actioned
4a. **Memory audit** — review entries added to `.claude/project/memory.md` during the session; confirm accuracy, rewrite vague entries, remove stale ones
5. **Session record** — saved to `.claude/sessions/<session-id>.md`
6. **Next session ID** — generated via the session-start hook

## Skill Backlog

**File:** `.claude/skill-backlog.md` (created on demand)

During any session, Claude silently logs observations about potential new skills or improvements to existing ones. Items are appended to this file without interrupting the workflow. The user reviews and promotes entries at their own pace.

## Project Skills

**Directory:** `.claude/project/skills/` (optional, not installed by default)

Projects can define skills specific to their own workflows in this directory. These are available alongside framework skills but are not promoted to the base framework. Create a subdirectory with a `SKILL.md` file following the same format as framework skills.

## Adding New Framework Skills

1. Create a subdirectory under `.claude/skills/` with a descriptive name
2. Add a `SKILL.md` file defining the skill's purpose, trigger conditions, steps, and allowed tools
3. Mirror the file to `source/.claude/skills/` so it is included in future `install.sh` runs
4. Claude Code will pick up the skill automatically
