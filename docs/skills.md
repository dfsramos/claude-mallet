# Skills

Skills are reusable capabilities defined as `SKILL.md` files inside `~/.claude/skills/`, installed once per machine and available in every project. A project can add its own in `.mallet/skills/`.

## Install

**File:** `install.md` (repo root — public-facing bootstrap)
**Triggered by:** A user pointing Claude at the framework repo URL

Installs the framework into `~/.claude/` from the remote GitHub repo. Requires no local checkout — only Claude Code and internet access. The install is machine-wide; the current working directory is irrelevant to it.

Flow:
1. Derives `owner/repo` from the URL
2. Queries the GitHub API for the default branch and HEAD commit SHA
3. Downloads the tarball from `github.com/{owner}/{repo}/archive/{sha}.tar.gz` to `/tmp`
4. Confirms the machine-wide target with the user, then backs up existing `~/.claude/` config
5. Backs up any existing `~/.claude/CLAUDE.md` to `CLAUDE.md.pre-mallet-<date>`, with confirmation
6. Runs `install-payload.sh` — installs each entry individually, reconciles the previous manifest, restores executable bits, writes `framework.json`
7. Runs `merge-settings.sh` — registers base hooks and the statusline without disturbing other keys
8. Runs `migrate/detect.sh` and offers to clean up any legacy per-project installs
9. Asks how `.mallet/` should be treated by git, and applies only what the user picks
10. Cleans up `/tmp` and detects project type for optional skill suggestions

Two things it deliberately does **not** do:

- **Remove a payload directory wholesale.** `~/.claude/skills/` and its siblings may hold user-authored entries. Replacement is per entry, and unclaimed entries are reported as preserved.
- **Overwrite `~/.claude/settings.json`.** It holds `model`, `effortLevel`, `enabledPlugins`, and the user's own hooks, so it is merged.

**`framework.json`** format — the `manifest` records what Mallet owns, so a later release can remove entries it drops without touching anything the user added:

```json
{
  "repo": "owner/repo",
  "version": "<full SHA>",
  "installed_at": "YYYY-MM-DD",
  "manifest": {
    "skills": ["adr", "discover", "..."],
    "agents": ["_contract.md", "..."],
    "templates": ["knowledge-skill", "mallet-gitignore"],
    "hooks": ["session-start.sh", "..."]
  }
}
```

## Migrate

**Directory:** `~/.claude/skills/migrate/`
**Triggered by:** `/migrate`, "clean up the old Mallet installs", the install flow, or a session-start legacy notice

Removes the per-project payload older Mallet versions left inside each repo. Mechanics live in two scripts beside `SKILL.md` — `detect.sh` and `migrate-repo.sh` — so the file-deleting logic is testable rather than prose.

Flow:
1. **Discover** — reads the `cwd` field from session transcripts under `~/.claude/projects/`, an exact record of every repo Claude has run in, with an optional bounded filesystem scan for repos never opened in Claude
2. **Detect** — classifies by *file presence*, never schema; installs exist in the wild whose `framework.json` is `{"commit": ..., "installed_at": ...}` with no `repo` or `version` key
3. **Back up** — one tarball per repo; a repo whose backup fails is skipped before anything is deleted
4. **Present and confirm** — lists what moves, what is deleted, and what is only reported
5. **Ask the VCS question once** — machine-wide ignore, per-repo ignore, commit it, or decide later
6. **Migrate per repo** — relocate state to `.mallet/`, remove untracked payload, prune `settings.json`, strip an untracked `CLAUDE.md`
7. **Report** — per repo, including every skipped tracked file

Hard guarantees:

| Guarantee | Why |
|---|---|
| Never modifies a git-tracked file | Changing committed content is the user's decision |
| Never writes an ignore file by default | VCS policy is not the framework's call |
| Never touches `.claude/settings.local.json` | User permissions |
| No backup, no deletion | A half-migrated repo is worse than an unmigrated one |

The `CLAUDE.md` strip is exact, not heuristic: it fetches the historical payload for the SHA that repo recorded from `raw.githubusercontent.com/<repo>/<sha>/CLAUDE.md` and diffs, so only genuinely project-authored content survives. If the fetch fails or the SHA is unknown, it skips rather than guessing.

## Hooks Setup

**Directory:** `~/.claude/skills/hooks-setup/`
**Triggered by:** `/hooks-setup`, "set up hooks", "enable typecheck", "enable push confirmation"

Activates optional hook scripts in the current project. The framework distributes hook scripts for all projects but only registers the default set at install time. `hooks-setup` is the activation mechanism for the opt-in tier.

1. **Audit** — reads `settings.json` and reports which optional hooks (`typecheck`, `push-confirm`, `explore-redirect`) are already registered
2. **Detect stack** — checks for `tsconfig.json` / `"typescript"` in `package.json` (TypeScript) and `vendor/bin/phpstan` (PHP)
3. **Present options** — lists unregistered hooks with descriptions; skips `typecheck` if neither stack is detected
4. **Register** — for each selected hook: verifies the script exists in `~/.claude/hooks/`, checks idempotency by script filename, appends to the correct event array in `settings.json` using Edit
5. **Confirm** — reports what was registered and what was skipped (already present / script missing / stack not detected)

## Preflight

**Directory:** `~/.claude/skills/preflight/`
**Triggered by:** `/preflight`, or when environment issues are suspected before git-heavy work

Runs four environment checks and reports results as a concise status block. Designed to catch recurring WSL2 and Git LFS issues before they derail a session.

1. **Worktree health** — `git worktree list --porcelain`; flags stale entries with Windows WSL gitdir paths and entries whose paths no longer exist on disk; runs `--dry-run` prune to show what would be removed (never prunes without confirmation)
2. **LFS hook check** — checks `.git/hooks/post-checkout` for `git lfs`; if present, flags that it will block `git worktree add` and offers the `--no-checkout` workaround
3. **Working tree state** — reports current branch name and whether the tree is clean
4. **Status summary** — one `[ok]` / `[warn]` / `[block]` line per check; outputs `preflight ok — no issues found` when everything passes

## Update

**Directory:** `~/.claude/skills/update/`
**Triggered by:** "update the framework", "update from `<url>`"

Upgrades the single machine-wide install. Requires `~/.claude/framework.json` to exist. There is nothing per-project to update — which is the point: eight installs across three versions existed precisely because updates used to be per repo.

Shares `install-payload.sh` and `merge-settings.sh` with the install flow, so the replacement rules live in one tested place rather than in two prose documents. It adds a version check that short-circuits with no writes when the local SHA already matches HEAD, a pre-update backup, and a closing legacy sweep via `migrate/detect.sh`.

Manifest reconciliation is what makes per-entry replacement safe over time: entries the previous manifest claimed but the new release no longer ships are removed, while entries it never claimed are left alone and reported as preserved. Without it, a skill dropped from a later release would linger in `~/.claude/skills/` forever.

---

## Project Discovery

**Directory:** `~/.claude/skills/discover/`
**Triggered by:** `/discover`, "discover this project", "analyze the codebase"

Structured analysis of a project's codebase to identify `.claude/` setup opportunities:

1. **Scan** — languages, frameworks, build tools, structure
2. **Critical files** — inbound-reference count script identifies the highest-centrality modules (god nodes); reported with reference count and why they matter. Skipped for small projects.
3. **External services** — SDKs, auth providers, data services, observability
4. **Augmentation opportunities** — MCP servers (e.g., Context7 for libraries with live docs), skill packs (e.g., Impeccable for frontend UI work), CLI-Anything harnesses (pre-built `SKILL.md` wrappers for ~100+ desktop/server apps — recommended when the project interacts with design, media, GIS, or automation software), and Graphify (knowledge graph tool — recommended for large, polyglot, or multi-modal codebases; skipped for small or simple projects)
5. **Focused questions** via `AskUserQuestion` to resolve priorities
6. **Research** — WebSearch for confirmed services, propose concrete skills
7. **Skill and documentation opportunities** — including connection data, project conventions for `.mallet/conventions.md`, and patterns promotable to the base framework
8. **Report** — saved to `.mallet/discovery-YYYY-MM-DD.md`
9. **Quick wins** — offer to implement high-value suggestions immediately

## Feature Planning

**Directory:** `~/.claude/skills/plan-feature/`
**Triggered by:** "plan a feature", "I want to build X", or "continue the Y feature"

Intake-to-execution pipeline. Supports resumption across sessions. All planning files are committed directly to `master` via a git worktree so plans remain visible regardless of the active branch.

1. **Pre-check** — reads existing plans from master; surfaces overlaps before creating anything new
2. **Intake** — broad questions (problem, users, success criteria, constraints, remote system involvement)
3. **Knowledge skill assessment** — if the feature touches a domain with strong conventions (API design, auth, data modelling, security, accessibility, performance, domain rules), offers to scaffold a knowledge skill
4. **Decompose** — confirms a slug; writes `plan.md`, `state.md`, and per-task stubs
5. **Execute (wave model)** — identifies tasks whose dependencies are satisfied (a wave); when parallel, dispatches each task to its own subagent so only results surface to the main context
6. **Resume** — loads `plan.md` and `state.md` from master

## Implement Feature

**Directory:** `~/.claude/skills/implement-feature/`
**Triggered by:** "implement this feature", "add X functionality", or any non-trivial code change

Orchestrates the full spec-to-review pipeline across seven named agents, each defined in `~/.claude/agents/` and bound to the shared output contract in `~/.claude/agents/_contract.md`.

| Step | Agent | Role |
|---|---|---|
| 1. Feature analysis | `feature-analyst` (Frida) | Turn the request into a structured spec |
| 2. Code analysis | `code-analyst` (Callum) | Read the codebase, produce a change plan |
| 3. Plan critique | `plan-critic` (Percy) | Challenge the plan against the spec |
| 4. Implementation | `implementer` (Ingrid) | Apply the approved plan |
| 5. Test | `test-runner` (Tobias) | Run the suite, return only signal |
| 6. Scope validation | `scope-validator` (Sylvie) | Confirm acceptance criteria met, no scope creep |
| 7. Code review | `code-reviewer` (Clifford) | Senior review — blocking vs non-blocking |

Pipeline state is checkpointed to `.mallet/pipeline-state/<slug>.md` after every step, so a session that ends mid-pipeline can resume from the last completed handoff rather than restarting.

Each stage has an iteration cap so a disagreeing agent pair cannot loop indefinitely: analysis plus critique share a budget of 2, implementation plus tests plus review share 2, and scope validation gets 1. A user resolving a blocker resets the relevant budget. When Percy's second critique contains only small concrete amendments, the skill folds them into Ingrid's prompt rather than blocking.

## Architecture Decision Records

**Directory:** `~/.claude/skills/adr/`
**Triggered by:** "record this decision", "create an ADR", "document why we chose X", `/adr`, or during `plan-feature` when a significant architectural choice is made

Captures a significant architectural decision in Nygard format so the rationale survives beyond the session.

1. **Locate** — finds `docs/adr/` and determines the next four-digit number; creates the directory if it doesn't exist
2. **Gather** — extracts context, decision, alternatives, and consequences from the conversation; asks only for what's missing
3. **Write** — creates `docs/adr/NNNN-<title>.md` with Context, Decision, Alternatives Considered, and Consequences sections
4. **Index** — appends to (or creates) `docs/adr/README.md`
5. **Link** — offers to reference the ADR from an active feature plan or mission file
6. **Commit** — stages and commits with `Add ADR-NNNN: <title>.`

## Checkpoint

**Directory:** `~/.claude/skills/checkpoint/`
**Triggered by:** "checkpoint", "save state", `/checkpoint`, or proactively before `/compact`

Persists in-progress session state to disk so it survives compaction or a restart. No summary or reflection — write-only. Complements `reviewing-sessions` (use checkpoint mid-session, wrap-up at the end).

1. **Lessons** — appends new corrections/rules to `.mallet/lessons.md` using the standard dated format; skips if nothing new
2. **Memory** — adds new facts to `.mallet/memory.md` (non-obvious commands, confirmed conventions, tool quirks); skips anything already in CLAUDE.md or a skill
3. **Mission state** — writes `.mallet/missions/active.md` if work is ongoing and multi-step; skips for single-session or complete work. Reads the file first: if it holds a *different* mission that is still open, writes to `.mallet/missions/<short-name>.md` instead and reports that both are live, rather than overwriting
4. **Confirm** — one-line report of what was written, e.g. `Checkpoint complete: lessons.md (+1), missions/active.md (updated)`

## Session Wrap-Up

**Directory:** `~/.claude/skills/reviewing-sessions/`
**Triggered by:** "wrap up", "all done", "end session"

Structured end-of-session retrospective. No session record files are written — skill and directive updates (step 4) do write to framework files.

1. **Session summary** — goal, approach, outcome
2. **What went well** — efficient tasks, effective patterns, good tool use
3. **What went poorly** — mistakes, user corrections, rule violations (with specific references)
3a. **Token efficiency** — flags patterns that drove unnecessary cost (long sessions without compaction, Write on existing files, verbose post-Bash responses, oversized subagents); adds CLAUDE.md directives for any gaps found
4. **Applied improvements** — updates to skills or directives based on session observations; skill backlog reviewed and actioned; **docs parity check** — any change to a skill, hook, or directive must reflect in the corresponding `docs/` section before the work counts as done
4a. **Memory audit** — review and revise `.mallet/memory.md` entries added during the session
4b. **Mission state** — if work continues beyond this session, write `.mallet/missions/active.md`; if the mission completed, move `active.md` to `.mallet/missions/archive/<session-id>.md`. Reads the file first: if it holds a *different* mission that is still open, either consolidates deliberately or leaves this session's mission in its own `.mallet/missions/<short-name>.md` with a cross-reference, and says which — a single `active.md` does not model two concurrent missions
5. **Close out** — clear task-notes scratchpad if used; confirm correct working branch; present the full wrap-up to the user

## Task Calibration

**Directory:** `~/.claude/skills/task-calibrate/`
**Triggered by:** `UserPromptSubmit` hook flagging high complexity (`[task-calibrate]`) or ultracode signals (`[ultracode]`), or explicit "check model for this" / `/task-calibrate`

Surfaces a model and execution-mode recommendation before work begins.

1. **Classify** — Mechanical (no model needed), Ultracode, Architectural, Complex, Routine, or Large Context
2. **Apply model matrix** — tier → recommended model + switch command; includes subagent-model table (Haiku for lookups, Sonnet for standard dev, Sonnet/Opus for deep analysis); Ultracode tier recommends the Workflow tool with Sonnet (sweep) or Opus (per-agent depth)
3. **Surface** — only interrupt when a switch is warranted; for Ultracode with an explicit prompt signal, proceed directly; for Ultracode hook-only, wait for confirmation
4. **Ultracode agent personas** — Workflow scripts should bind agents to existing mallet personas via `agentType`: `code-analyst` (Callum), `code-reviewer` (Clifford), `feature-analyst` (Frida), `implementer` (Ingrid), `plan-critic` (Percy), `scope-validator` (Sylvie), `test-runner` (Tobias). Novel roles get an inline persona in the same named style.

## Systematic Debugging

**Directory:** `~/.claude/skills/systematic-debugging/`
**Triggered by:** Debugging errors or unexpected behaviour; also after a failed fix attempt

Four-phase methodology enforcing root cause investigation before any fix.

1. **Root cause investigation** — reproduce consistently; read full error and trace; review recent changes; add diagnostic instrumentation
2. **Pattern analysis** — locate a working analogue (if one exists); otherwise reason from first principles across touched dependencies
3. **Hypothesis and testing** — falsifiable hypothesis; one variable at a time; discard or refine on evidence
4. **Implementation** — write a failing test first (when behaviour is testable); apply a single targeted fix; confirm pass and no regressions

Hard rule: no fix is applied before root cause is confirmed. Three consecutive failed fixes in different locations signals an architectural problem — stop and map the system rather than continue guessing.

Includes a **condition-based waiting** pattern: replace arbitrary `sleep` delays in tests with polling for the actual condition (check every 10ms, timeout with a descriptive message). Eliminates flaky timing-dependent failures.

## Receiving Code Review

**Directory:** `~/.claude/skills/receiving-code-review/`
**Triggered by:** A code review is returned from any source (Clifford, human reviewer, PR feedback) and needs to be processed

Methodical framework for processing review feedback without performative compliance or uncritical acceptance.

1. **Understand completely** — read and classify all feedback (blocking / non-blocking) before acting on any item
2. **Verify against reality** — confirm each flagged location and described behaviour matches the actual code before accepting the review as correct
3. **Evaluate technically** — test each blocking item for correctness, functionality impact, context completeness, scope (YAGNI), and architectural fit; surface conflicts with a specific technical explanation rather than silently complying
4. **Respond factually** — describe the actual fix, not praise ("Changed guard at `auth.ts:42`" not "Great catch!"); push back technically when warranted
5. **Implement methodically** — locate, understand, apply targeted fixes; batch all blocking fixes before re-review

Hard rule: reviewer seniority does not override technical correctness. An incorrect fix applied under social pressure ships wrong code.

## Dispatching Parallel Agents

**Directory:** `~/.claude/skills/dispatching-parallel-agents/`
**Triggered by:** 3 or more independent failures or problem domains, or a large task partitioned into non-overlapping workstreams

Structured approach for concurrent subagent dispatch when problems are genuinely independent.

Use when all three hold: (1) 3+ independent domains, each understandable in isolation; (2) no shared files between agents; (3) no sequential dependency between tracks.

1. **Identify domains** — confirm each failure or workstream can be fully resolved without knowledge of the others
2. **Scope tasks** — write a self-contained description per agent (specific error, file paths, test command, output contract)
3. **Dispatch in parallel** — send all agents in a **single message** (one tool call per domain)
4. **Review and integrate** — read all results before acting; check for unexpected file conflicts; run the full test suite once
5. **Surface results** — per-domain status, files changed, verification outcome

## Create PR

**Directory:** `~/.claude/skills/create-pr/`
**Triggered by:** "create PR", "open a PR", "make a pull request"

Generates a structured, non-technical PR summary (What Changed / Why / Customer Impact / Risk & Mitigation), pushes the branch with explicit confirmation, and opens the PR via `gh pr create`. The default branch is detected dynamically via `git symbolic-ref refs/remotes/origin/HEAD` — works with any main-branch convention (`master`, `main`, `trunk`, etc.).

---

## Harvest (framework maintenance, not installed)

**Directory:** `.mallet/skills/harvest/`
**Triggered by:** "harvest", "run harvest", or "harvest `<project-path>`"

Reviews a target project for improvements worth pulling back into the framework base. Runs in the claude-mallet repo only.

1. **Pull check** — ensures the framework repo is up to date before comparing anything
2. **Project skills** — scans `TARGET/.mallet/skills/`; offers to promote selected skills into `~/.claude/skills/`
3. **Overrides** — scans `TARGET/.mallet/overrides/`; surfaces each override with a summary and asks whether it reveals a gap worth folding into the base skill (overrides are project-specific by design and never auto-promoted)

Framework drift in the target is intentionally **not** addressed — local edits to framework-managed files are overwritten on the next `update`. If a target diverges, the clean path is an override, a project skill, or a direct PR to the framework.

## Knowledge Skill Template

**File:** `~/.claude/templates/knowledge-skill/SKILL.md`
**Used by:** `plan-feature` when a feature domain warrants encoding expertise

Template for creating domain knowledge skills — skills that inject expertise (principles, decision rules, reference data, anti-patterns) rather than orchestrate a workflow. Copy to `.mallet/skills/<domain>-knowledge/SKILL.md` and fill in domain-specific content.

## Project Memory

**File:** `.mallet/memory.md` (created on demand)

Persistent fact store for project-specific knowledge that accumulates across sessions. Unlike skills (procedures) or CLAUDE.md (rules), memory holds facts: preferred commands, gotchas, conventions, tool preferences.

Claude appends entries during sessions and audits them at wrap-up. The full file is injected into context at session start by the [session-start hook](hooks.md#session-start-hook).

## Skill Backlog

**File:** `.mallet/skill-backlog.md` (created on demand)

Silent log of potential new skills or improvements captured during sessions. Reviewed during wrap-up.

## Project Skills

**Directory:** `.mallet/skills/` (optional)

Project-specific skills that sit alongside framework skills but are not installed into other projects. Same `SKILL.md` format.

## Skill Overrides

**Directory:** `.mallet/overrides/` (optional, one file per overridden skill)

Per-skill amendments to base framework skills, indexed via a "Skill Overrides" section in `.mallet/conventions.md`. Before executing a listed skill, Claude reads `.mallet/overrides/<skill-name>.md` and applies its contents as amendments — overrides win on conflict.

Override files are created and maintained by Claude on user request. Because the index lives in `.mallet/conventions.md` (already in context), Claude never probes the filesystem for absent overrides. See the [Skill Overrides directive](directives.md#skill-overrides).

## Adding New Framework Skills

1. Create `~/.claude/skills/<name>/SKILL.md`
2. Write a `description` that states **trigger conditions only** (when to invoke), not what the skill does
3. Commit; it will be picked up by Claude Code and distributed to target projects on the next install/update
