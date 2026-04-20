# Skills

Skills are reusable capabilities defined as `SKILL.md` files inside `.claude/skills/`. Each skill lives in its own subdirectory and is automatically available to Claude Code when the project is opened.

## Install

**File:** `install.md` (repo root — public-facing bootstrap)
**Triggered by:** A user pointing Claude at the framework repo URL

Installs the framework into the user's current working directory from the remote GitHub repo. Requires no local checkout of the framework — the user only needs Claude Code and internet access.

Flow:
1. Derives `owner/repo` from the URL
2. Queries the GitHub API for the default branch and HEAD commit SHA
3. Downloads the tarball from `github.com/{owner}/{repo}/archive/{sha}.tar.gz` to `/tmp`
4. Removes framework-managed paths in the target (`.claude/hooks/`, `.claude/skills/`, `.claude/templates/`, `.claude/statusline.sh`, `.claude/settings.json`, `CLAUDE.md`)
5. Copies the new versions into place with `cp -r` — never touches `.claude/project/`, `.claude/settings.local.json`, or `.claude/framework.json`
6. Restores hook executable bits
7. Writes `.claude/framework.json` with repo, version (commit SHA), and install date
8. Cleans up `/tmp` and detects project type for optional skill suggestions

This is a **source-of-truth install** — framework files overwrite any local equivalents. Local customisations belong in `.claude/project/` or `.claude/settings.local.json`.

**`framework.json`** format:
```json
{ "repo": "owner/repo", "version": "<full SHA>", "installed_at": "YYYY-MM-DD" }
```

## Update

**Directory:** `.claude/skills/update/`
**Triggered by:** "update the framework", "update from `<url>`"

Upgrades the framework in the current project to the latest remote version. Requires `.claude/framework.json` to exist.

Mechanically identical to install, with a version check: the skill queries the current HEAD SHA via the GitHub API and short-circuits if it matches `framework.json.version`. Otherwise it re-runs the install flow, preserving `.claude/project/`, `.claude/settings.local.json`, and bumping `framework.json` to the new SHA.

---

## Project Discovery

**Directory:** `.claude/skills/discover/`
**Triggered by:** `/discover`, "discover this project", "analyze the codebase"

Structured analysis of a project's codebase to identify `.claude/` setup opportunities:

1. **Scan** — languages, frameworks, build tools, structure
2. **External services** — SDKs, auth providers, data services, observability
3. **Augmentation opportunities** — MCP servers (e.g., Context7 for libraries with live docs), skill packs (e.g., Impeccable for frontend UI work)
4. **Focused questions** via `AskUserQuestion` to resolve priorities
5. **Research** — WebSearch for confirmed services, propose concrete skills
6. **Skill and documentation opportunities** — including connection data, project conventions for `.claude/project/CLAUDE.md`, and patterns promotable to the base framework
7. **Report** — saved to `.claude/project/discovery-YYYY-MM-DD.md`
8. **Quick wins** — offer to implement high-value suggestions immediately

## Feature Planning

**Directory:** `.claude/skills/plan-feature/`
**Triggered by:** "plan a feature", "I want to build X", or "continue the Y feature"

Intake-to-execution pipeline. Supports resumption across sessions. All planning files are committed directly to `master` via a git worktree so plans remain visible regardless of the active branch.

1. **Pre-check** — reads existing plans from master; surfaces overlaps before creating anything new
2. **Intake** — broad questions (problem, users, success criteria, constraints, remote system involvement)
3. **Knowledge skill assessment** — if the feature touches a domain with strong conventions (API design, auth, data modelling, security, accessibility, performance, domain rules), offers to scaffold a knowledge skill
4. **Decompose** — confirms a slug; writes `plan.md`, `state.md`, and per-task stubs
5. **Execute (wave model)** — identifies tasks whose dependencies are satisfied (a wave); when parallel, dispatches each task to its own subagent so only results surface to the main context
6. **Resume** — loads `plan.md` and `state.md` from master

## Session Wrap-Up

**Directory:** `.claude/skills/reviewing-sessions/`
**Triggered by:** "wrap up", "all done", "end session"

Structured end-of-session retrospective. Wrap-ups are **conversational only** — no files are written to disk.

1. **Session summary** — goal, approach, outcome
2. **What went well** — efficient tasks, effective patterns, good tool use
3. **What went poorly** — mistakes, user corrections, rule violations (with specific references)
3a. **Token efficiency** — flags patterns that drove unnecessary cost (long sessions without compaction, Write on existing files, verbose post-Bash responses, oversized subagents); adds CLAUDE.md directives for any gaps found
4. **Applied improvements** — updates to skills or directives based on session observations; skill backlog reviewed and actioned
4a. **Memory audit** — review and revise `.claude/project/memory.md` entries added during the session
4b. **Mission state** — if work continues beyond this session, write `.claude/project/missions/active.md`

## Task Calibration

**Directory:** `.claude/skills/task-calibrate/`
**Triggered by:** `UserPromptSubmit` hook flagging high complexity (mandatory invocation), or explicit "check model for this" / `/task-calibrate`

Surfaces a model and effort recommendation before work begins.

1. **Classify** — Architectural, Complex, Routine, or Large Context
2. **Apply model matrix** — tier → recommended model + switch command
3. **Subagent guidance** — model selection for spawned agents (Haiku for lookups, Sonnet for standard dev, Sonnet/Opus for deep analysis)
4. **Surface** — only interrupt when a switch is warranted; proceed silently otherwise

## Systematic Debugging

**Directory:** `.claude/skills/systematic-debugging/`
**Triggered by:** Debugging errors or unexpected behaviour; also after a failed fix attempt

Four-phase methodology enforcing root cause investigation before any fix.

1. **Root cause investigation** — reproduce consistently; read full error and trace; review recent changes; add diagnostic instrumentation
2. **Pattern analysis** — locate a working analogue (if one exists); otherwise reason from first principles across touched dependencies
3. **Hypothesis and testing** — falsifiable hypothesis; one variable at a time; discard or refine on evidence
4. **Implementation** — write a failing test first (when behaviour is testable); apply a single targeted fix; confirm pass and no regressions

Hard rule: no fix is applied before root cause is confirmed.

## Create PR

**Directory:** `.claude/skills/create-pr/`
**Triggered by:** "create PR", "open a PR", "make a pull request"

Generates a structured, non-technical PR summary (What Changed / Why / Customer Impact / Risk & Mitigation), pushes the branch with explicit confirmation, and opens the PR via `gh pr create`. The default branch is detected dynamically via `git symbolic-ref refs/remotes/origin/HEAD` — works with any main-branch convention (`master`, `main`, `trunk`, etc.).

---

## Harvest (framework maintenance, not installed)

**Directory:** `.claude/project/skills/harvest/`
**Triggered by:** "harvest", "run harvest", or "harvest `<project-path>`"

Promotes project-specific skills from an installed project into the framework base. Runs in the ai-framework repo only.

## Knowledge Skill Template

**File:** `.claude/templates/knowledge-skill/SKILL.md`
**Used by:** `plan-feature` when a feature domain warrants encoding expertise

Template for creating domain knowledge skills — skills that inject expertise (principles, decision rules, reference data, anti-patterns) rather than orchestrate a workflow. Copy to `.claude/project/skills/<domain>-knowledge/SKILL.md` and fill in domain-specific content.

## Project Memory

**File:** `.claude/project/memory.md` (created on demand)

Persistent fact store for project-specific knowledge that accumulates across sessions. Unlike skills (procedures) or CLAUDE.md (rules), memory holds facts: preferred commands, gotchas, conventions, tool preferences.

Claude appends entries during sessions and audits them at wrap-up. The full file is injected into context at session start by the [session-start hook](hooks.md#session-start-hook).

## Skill Backlog

**File:** `.claude/project/skill-backlog.md` (created on demand)

Silent log of potential new skills or improvements captured during sessions. Reviewed during wrap-up.

## Project Skills

**Directory:** `.claude/project/skills/` (optional)

Project-specific skills that sit alongside framework skills but are not installed into other projects. Same `SKILL.md` format.

## Adding New Framework Skills

1. Create `.claude/skills/<name>/SKILL.md`
2. Write a `description` that states **trigger conditions only** (when to invoke), not what the skill does
3. Commit; it will be picked up by Claude Code and distributed to target projects on the next install/update
