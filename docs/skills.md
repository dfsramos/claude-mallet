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

## Feature Planning

**Directory:** `.claude/skills/plan-feature/`
**Triggered by:** Phrases like "plan a feature", "I want to build X", or "continue the Y feature"

An intake-to-execution pipeline for planning and implementing features. Supports resuming across sessions. All planning files are committed directly to `master` via a temporary git worktree so plans remain visible regardless of the active branch.

1. **Pre-check** — reads existing plans from master; surfaces overlaps before creating anything new
2. **Intake** — broad questions (problem, users, success criteria, constraints, remote system involvement)
3. **Decompose** — confirms a slug, writes `plan.md` (task list with dependencies and parallel flags) and per-task stub files under `.claude/features/<slug>/tasks/`
4. **Execute** — runs tasks in dependency order; offers parallel execution where allowed; applies autonomy rules (local work proceeds freely; remote/production writes require confirmation); updates task and plan status on master after each task
5. **Resume** — if a plan already exists, skips intake and picks up from the first incomplete task

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

## Project Memory

**File:** `.claude/project/memory.md` (installed from `source/`)

A persistent fact store for project-specific knowledge that accumulates across sessions. Unlike skills (procedures) or CLAUDE.md (rules), memory holds facts: things worth knowing but not worth formalising.

The file is structured into four categories:

- **Commands & Access Patterns** — preferred commands, access methods, tool invocations
- **Conventions** — naming, structure, and workflow patterns specific to this project
- **Gotchas** — non-obvious behaviours, traps, or things that don't work as expected
- **Preferences** — tool choices, flag preferences, approaches the user consistently favours

Claude appends entries during sessions when it discovers something useful. At session wrap-up, entries are audited for accuracy. The full file is injected into Claude's context at session start by the [session-start hook](hooks.md#session-start-hook).

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
