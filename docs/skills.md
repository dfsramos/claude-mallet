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

## Hooks Setup

**Directory:** `.claude/skills/hooks-setup/`
**Triggered by:** `/hooks-setup`, "set up hooks", "enable typecheck", "enable push confirmation"

Activates optional hook scripts in the current project. The framework distributes hook scripts for all projects but only registers the default set at install time. `hooks-setup` is the activation mechanism for the opt-in tier.

1. **Audit** — reads `settings.json` and reports which optional hooks (`typecheck`, `push-confirm`) are already registered
2. **Detect stack** — checks for `tsconfig.json` / `"typescript"` in `package.json` (TypeScript) and `vendor/bin/phpstan` (PHP)
3. **Present options** — lists unregistered hooks with descriptions; skips `typecheck` if neither stack is detected
4. **Register** — for each selected hook: verifies the script exists in `.claude/hooks/`, checks idempotency by script filename, appends to the correct event array in `settings.json` using Edit
5. **Confirm** — reports what was registered and what was skipped (already present / script missing / stack not detected)

## Preflight

**Directory:** `.claude/skills/preflight/`
**Triggered by:** `/preflight`, or when environment issues are suspected before git-heavy work

Runs four environment checks and reports results as a concise status block. Designed to catch recurring WSL2 and Git LFS issues before they derail a session.

1. **Worktree health** — `git worktree list --porcelain`; flags stale entries with Windows WSL gitdir paths and entries whose paths no longer exist on disk; runs `--dry-run` prune to show what would be removed (never prunes without confirmation)
2. **LFS hook check** — checks `.git/hooks/post-checkout` for `git lfs`; if present, flags that it will block `git worktree add` and offers the `--no-checkout` workaround
3. **Working tree state** — reports current branch name and whether the tree is clean
4. **Status summary** — one `[ok]` / `[warn]` / `[block]` line per check; outputs `preflight ok — no issues found` when everything passes

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
4. **Applied improvements** — updates to skills or directives based on session observations; skill backlog reviewed and actioned; **docs parity check** — any change to a skill, hook, or directive must reflect in the corresponding `docs/` section before the work counts as done
4a. **Memory audit** — review and revise `.claude/project/memory.md` entries added during the session
4b. **Mission state** — if work continues beyond this session, write `.claude/project/missions/active.md`; if the mission completed, move `active.md` to `.claude/project/missions/archive/<session-id>.md`

## Task Calibration

**Directory:** `.claude/skills/task-calibrate/`
**Triggered by:** `UserPromptSubmit` hook flagging high complexity (mandatory invocation), or explicit "check model for this" / `/task-calibrate`

Surfaces a model and effort recommendation before work begins.

1. **Classify** — Architectural, Complex, Routine, or Large Context
2. **Apply model matrix** — tier → recommended model + switch command; includes a subagent-model table (Haiku for lookups, Sonnet for standard dev, Sonnet/Opus for deep analysis)
3. **Surface** — only interrupt when a switch is warranted; proceed silently otherwise

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

Reviews a target project for improvements worth pulling back into the framework base. Runs in the claude-mallet repo only.

1. **Pull check** — ensures the framework repo is up to date before comparing anything
2. **Project skills** — scans `TARGET/.claude/project/skills/`; offers to promote selected skills into `.claude/skills/`
3. **Overrides** — scans `TARGET/.claude/project/overrides/`; surfaces each override with a summary and asks whether it reveals a gap worth folding into the base skill (overrides are project-specific by design and never auto-promoted)

Framework drift in the target is intentionally **not** addressed — local edits to framework-managed files are overwritten on the next `update`. If a target diverges, the clean path is an override, a project skill, or a direct PR to the framework.

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

## Skill Overrides

**Directory:** `.claude/project/overrides/` (optional, one file per overridden skill)

Per-skill amendments to base framework skills, indexed via a "Skill Overrides" section in `.claude/project/CLAUDE.md`. Before executing a listed skill, Claude reads `.claude/project/overrides/<skill-name>.md` and applies its contents as amendments — overrides win on conflict.

Override files are created and maintained by Claude on user request. Because the index lives in `.claude/project/CLAUDE.md` (already in context), Claude never probes the filesystem for absent overrides. See the [Skill Overrides directive](directives.md#skill-overrides).

## Adding New Framework Skills

1. Create `.claude/skills/<name>/SKILL.md`
2. Write a `description` that states **trigger conditions only** (when to invoke), not what the skill does
3. Commit; it will be picked up by Claude Code and distributed to target projects on the next install/update
