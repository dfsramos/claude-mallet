# Skills

Skills are reusable capabilities defined as `SKILL.md` files inside `.claude/skills/`. Each skill lives in its own subdirectory and is automatically available to Claude Code when the project is opened.

## Install

**File:** `install.md` (repo root — public-facing bootstrap)
**Triggered by:** A new user pointing Claude at the repo URL

Installs the AI framework into the user's current working directory from a remote GitHub repository. Requires no local checkout of the framework repo — the user only needs Claude and `git` available.

Flow:
1. Derives `owner/repo` from the provided GitHub URL
2. Clones the repo to a temporary directory via `git clone --depth=1` (auth handled by the user's existing `git` credentials)
3. Inspects the target for existing installations and local customisations
4. Reports a pre-flight summary and resolves any conflicts before writing files
5. Copies all files from `source/` to the current directory using Read + Write for new files, Read + Edit for existing files being overwritten (no shell copies)
6. Writes `.claude/framework.json` with the repo slug, commit hash, and install date
7. Sets hook permissions and updates `.gitignore`
8. Cleans up the temporary directory
9. Prints a summary including the installed version hash

**`framework.json`** is written on every install and update. It is consumed by the session-start hook to perform version checks. Format:
```json
{
  "repo": "owner/repo",
  "version": "<full commit hash>",
  "installed_at": "YYYY-MM-DD"
}
```

## Update

**Directory:** `.claude/skills/update/` (installed into target projects via `source/`)
**Triggered by:** Phrases like "update the framework", "update from `<url>`"

Upgrades the framework in the current project to the latest version from the remote repository. Requires `.claude/framework.json` to exist (set during install).

Flow:
1. Reads `framework.json` to confirm the installed repo and hash
2. Clones the latest version to a temporary directory and captures the new commit hash
3. Short-circuits immediately if already up to date
4. Diffs each source file against the installed version — files identical to upstream auto-update; files that differ are flagged as conflicts for user review
5. Applies updated files: Write for new files (Added), Edit for existing files (Updated/Merged)
6. Overwrites `framework.json` with the new hash and date
7. Cleans up and prints a summary showing the version transition

---

## Project Discovery

**Directory:** `.claude/skills/discover/`
**Triggered by:** `/discover`, or phrases like "discover this project" or "analyze the codebase"

A structured analysis of a project's codebase to identify opportunities for improving the `.claude/` setup. The skill runs interactively and produces:

1. **Initial scan** — languages, frameworks, build tools, project structure
2. **External service detection** — API clients, SDKs, auth providers, data services
3. **MCP server opportunities** — assesses whether the project would benefit from live documentation servers (e.g., Context7 for projects with actively-developed third-party libraries); project-scoped, added to `.mcp.json` at the project root
4. **Skill opportunities** — repeatable patterns that could become skills (deployments, DB ops, testing)
5. **Connection data** — services and systems that should have connection templates documented
6. **Project conventions** — patterns worth capturing in `.claude/project/CLAUDE.md`
7. **Promotable patterns** — generic enough to move into the base framework
8. **Discovery report** — saved to `.claude/project/discovery-YYYY-MM-DD.md`
9. **Quick wins** — offer to immediately implement high-value stub skills, conventions, or MCP server configs

## Feature Planning

**Directory:** `.claude/skills/plan-feature/`
**Triggered by:** Phrases like "plan a feature", "I want to build X", or "continue the Y feature"

An intake-to-execution pipeline for planning and implementing features. Supports resuming across sessions. All planning files are committed directly to `master` via a temporary git worktree so plans remain visible regardless of the active branch.

1. **Pre-check** — reads existing plans from master; surfaces overlaps before creating anything new
2. **Intake** — broad questions (problem, users, success criteria, constraints, remote system involvement)
3. **Knowledge skill assessment** — checks whether the feature operates in a domain with strong conventions (API design, auth, data modelling, security, accessibility) and offers to scaffold a knowledge skill alongside the plan
4. **Decompose** — confirms a slug; writes `plan.md` (task list with dependencies and parallel flags), `state.md` (running log of decisions and blockers), and per-task stub files under `.claude/features/<slug>/tasks/`; each task stub includes a TDD checklist by default
5. **Execute (wave model)** — identifies all tasks whose dependencies are satisfied (a wave), presents parallel candidates, executes the wave, logs decisions and blockers to `state.md`, then reassesses for the next wave
6. **Resume** — loads `plan.md` and `state.md` from master; reads state first to recover decisions and open blockers from prior sessions

## Session Wrap-Up

**Directory:** `.claude/skills/reviewing-sessions/`
**Triggered by:** Phrases like "wrap up", "all done", or "end session"

A structured end-of-session retrospective covering:

1. **Session summary** — goal, approach, outcome
2. **What went well** — efficient tasks, effective patterns, good tool use
3. **What went poorly** — mistakes, user corrections, rule violations (with specific references)
3a. **Token efficiency** — reads the session turn count from `/tmp/ai-framework-turns-<id>`; flags patterns that drove unnecessary costs (runaway sessions without compaction, Write on existing files, verbose post-Bash responses, Sonnet subagents that could have been Haiku); adds CLAUDE.md directives for any gaps found
4. **Applied improvements** — updates to skills or directives based on session observations; skill backlog reviewed and actioned
4a. **Memory audit** — review entries added to `.claude/project/memory.md` during the session; confirm accuracy, rewrite vague entries, remove stale ones

## Task Calibration

**Directory:** `.claude/skills/task-calibrate/`
**Triggered by:** The `UserPromptSubmit` hook flagging high complexity, or explicit invocation via "check model for this" or "/task-calibrate"

Assesses the current task and surfaces a model and effort recommendation before work begins.

1. **Classify** — assigns the task to one of three tiers: Architectural, Complex, or Routine
2. **Apply the model matrix** — maps tier to recommended model:
   - Architectural → Opus (fewer first-attempt errors on complex design; net cost often lower than multiple Sonnet correction rounds)
   - Complex → Sonnet
   - Routine → Haiku (new session, T ≤ 2) or Sonnet (current session) — pure boilerplate tasks produce identical results on Haiku at significantly lower output cost; session-switch is only suggested when the turn count is low enough that the overhead is worth it
3. **Subagent guidance** — separately covers which model to use when spawning agents: Haiku for file reads and lookups, Sonnet for standard dev, Sonnet/Opus for deep analysis
4. **Surface the recommendation** — states tier, model, and one-sentence reason; pauses for confirmation when recommending Opus or Haiku (new session); skips the prompt entirely for Sonnet-tier tasks

## Systematic Debugging

**Directory:** `.claude/skills/systematic-debugging/`
**Triggered by:** Debugging an error, investigating unexpected behaviour, or when a previous fix attempt has failed

A four-phase methodology that enforces root cause investigation before any fix is attempted.

1. **Root cause investigation** — reproduce the failure consistently; read the full error and stack trace; review recent changes; add diagnostic instrumentation at component boundaries
2. **Pattern analysis** — locate the closest working analogue; compare implementations completely; list every difference; map all touched dependencies
3. **Hypothesis and testing** — state a specific, falsifiable hypothesis; change one variable at a time; discard or refine based on evidence
4. **Implementation** — write a failing test first; confirm it fails; apply a single targeted fix; confirm it passes; confirm no regressions

Hard rule: no fix is applied before root cause is confirmed.

## Harvest

**Directory:** `.claude/project/skills/harvest/` (framework-specific, not installed into target projects)
**Triggered by:** "harvest", "run harvest", or "harvest `<project-path>`"

Promotes project-specific skills from an installed project into the framework base, and reconciles framework drift in the target project. Runs in three phases:

1. **Pull check** — fetches and fast-forwards the ai-framework repo to ensure comparisons are against the latest source
2. **Drift detection** — diffs every file under `source/` against its counterpart in the target; presents a human-readable summary of changes and lets the user select which files to update
3. **Skill promotion** — scans `TARGET/.claude/project/skills/`; lets the user select skills to copy into `source/.claude/skills/` and removes them from the target project

After promotion, re-run the `install` skill on the target to propagate newly promoted base skills.

## Knowledge Skill Template

**File:** `.claude/templates/knowledge-skill/SKILL.md`
**Used by:** `plan-feature` (step 2b) when a feature domain warrants encoding expertise

A template for creating domain knowledge skills — skills that inject expertise (principles, decision rules, reference data, anti-patterns) rather than orchestrate a workflow. Structured with four sections: core principles, decision framework, reference table, and pre-delivery checklist.

Copy to `.claude/project/skills/<domain>-knowledge/SKILL.md` and fill in domain-specific content.

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

**File:** `.claude/project/skill-backlog.md` (created on demand)

During any session, Claude silently logs observations about potential new skills or improvements to existing ones. Items are appended to this file without interrupting the workflow. The user reviews and promotes entries at their own pace.

## Project Skills

**Directory:** `.claude/project/skills/` (optional, not installed by default)

Projects can define skills specific to their own workflows in this directory. These are available alongside framework skills but are not promoted to the base framework. Create a subdirectory with a `SKILL.md` file following the same format as framework skills.

## Adding New Framework Skills

1. Create a subdirectory under `.claude/skills/` with a descriptive name
2. Add a `SKILL.md` file defining the skill's purpose, trigger conditions, steps, and allowed tools
3. Mirror the file to `source/.claude/skills/` so it is included in future installs and updates
4. Claude Code will pick up the skill automatically
