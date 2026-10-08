# Skills

Skills are reusable capabilities defined as `SKILL.md` files inside `plugin/skills/`, shipped with the `mallet` plugin and available in every project once it is installed. They are namespaced at runtime — `/mallet:<name>`, agent type `mallet:<name>` for the review-pipeline agents. A project can add its own in `.mallet/skills/`, which are not namespaced and not part of the plugin.

Skills marked **manual-only** below carry `disable-model-invocation: true` in their frontmatter: Claude will not invoke them on its own judgment, only when the user explicitly asks or runs the slash command.

## Setup

**Directory:** `plugin/skills/setup/`
**Triggered by:** `/mallet:setup` (or `/setup`), "set up Mallet", "install the Mallet statusline", or right after installing the plugin — **manual-only**

One-time setup for what a plugin cannot configure by itself. Each step is independent — the user can decline any of them — and the skill reports what was done at the end.

1. **Statusline** — plugins cannot set the main `statusLine` (only `agent`/`subagentStatusLine` settings take effect), so this copies `${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh` to `${CLAUDE_PLUGIN_DATA}/statusline.sh` and points `~/.claude/settings.json`'s `statusLine` at that copy, backing the settings file up first and asking before replacing an existing non-Mallet `statusLine`
2. **Auto-update** — tells the user background auto-update is off by default for third-party marketplaces and how to turn it on (`/plugin` → Marketplaces → claude-mallet → Enable auto-update), or the on-demand alternative (`/plugin marketplace update claude-mallet`)
3. **Legacy Mallet memory files** — if `.mallet/memory.md` or `.mallet/lessons.md` exist in the current project, offers to fold them into Claude Code's auto memory (facts become `project`/`reference` memories, lessons become `feedback` memories); never deletes or edits the source files
4. **Transition leftovers** — if `~/.claude/skills/migrate/` contains only the stub `detect.sh` and a `MALLET-TRANSITION-STUB` marker left by a prior user-level-install transition, offers to remove the directory
5. **Report** — one line per step: done, skipped, or not applicable

## Migrate

**Directory:** `plugin/skills/migrate/`
**Triggered by:** `/mallet:migrate`, "clean up the old Mallet installs", "remove the per-project Mallet", or a session-start notice reporting a legacy per-project payload in the current repo

Removes the per-project payload that Mallet versions older than the user-level install left inside each repo. Mechanics live in two scripts beside `SKILL.md`, referenced via `${CLAUDE_SKILL_DIR}` so they resolve inside the installed plugin — `detect.sh` and `migrate-repo.sh` — so the file-deleting logic is testable rather than prose.

Non-negotiables, enforced by the scripts:

| Guarantee | Why |
|---|---|
| Tracked files never modified | A git-tracked `CLAUDE.md` or `settings.json` is reported, never touched |
| No ignore file written by default | Whether `.mallet/` is tracked is the user's decision |
| `.claude/settings.local.json` never touched | User permissions |
| No backup, no deletion | A repo whose backup fails is skipped whole |

Flow:
1. **Discover** — `${CLAUDE_SKILL_DIR}/detect.sh`, with candidates from the `cwd` recorded in session transcripts under `~/.claude/projects/`, optionally extended with `--roots <dir>...`; emits TSV (`repo`, `sha`, `recorded-repo`, `claude-md-state`)
2. **Present** — what moves (`.claude/project/`, `.claude/features/`, `.claude/pipeline-state/` into `.mallet/`), what is deleted (untracked payload only), what is skipped (every tracked file, named), and the per-repo backup path
3. **Confirm** — destructive-operation rules apply; confirming the list once covers all repos, then reports per repo as it goes
4. **Ask the VCS question, once** — ignore machine-wide (`core.excludesFile`), ignore per-repo (`.git/info/exclude`), commit it (mentions `${CLAUDE_SKILL_DIR}/mallet-gitignore` as an opt-in template), or decide later
5. **Migrate** — resolves the historical payload from `raw.githubusercontent.com/<recorded-repo>/<sha>/CLAUDE.md` so the `CLAUDE.md` strip is exact rather than heuristic (cached per SHA), then runs `${CLAUDE_SKILL_DIR}/migrate-repo.sh <repo> --payload ... --yes`; verifies `git status --porcelain` after each repo
6. **Report** — per repo: moved, deleted, pruned, stripped, skipped, backup path; a reminder that Mallet itself now comes from the plugin, so nothing Mallet-related should remain in the repo besides `.mallet/`

## Hooks Setup

**Directory:** `plugin/skills/hooks-setup/`
**Triggered by:** `/mallet:hooks-setup`, "set up hooks", "enable typecheck", "disable typecheck", turning the command guard on or off — **manual-only**

Turns the optional hooks on or off for the current project. The plugin registers every hook globally; an optional hook only *acts* in projects carrying its marker, so this skill edits no settings file — it only creates or removes the marker.

| Hook | Event | Marker |
|---|---|---|
| `typecheck` | Records edits (PostToolUse), checks them once at turn end (Stop) | `.mallet/typecheck.enabled` |
| `command-guard` | PreToolUse on `Bash` | `.mallet/command-guard.enabled` |

1. **Report current state** — checks the marker; also checks `.claude/settings.json`/`settings.local.json` for a pre-plugin registration referencing `.claude/hooks/typecheck.sh`, a path that no longer exists, and offers to remove that stale entry without touching anything else
2. **Detect the stack** — `tsconfig.json` for TypeScript, `vendor/bin/phpstan` for PHP; says typecheck would do nothing if neither is present; command-guard applies to any stack and is recommended where Bash permissions are broad or auto mode is used
3. **Apply the choice** — enable by creating the hook's marker (`mkdir -p .mallet && touch .mallet/<hook>.enabled`); disable by removing only that marker
4. **Confirm** — reports the new state and any stale registration removed or left in place

`git push` confirmation is no longer a hook — the skill points users at a `permissions.ask` rule (`"Bash(git push *)"`) instead, which Claude Code enforces natively.

## Preflight

**Directory:** `plugin/skills/preflight/`
**Triggered by:** `/mallet:preflight`, or when environment issues are suspected before git-heavy work

Runs four environment checks and reports results as a concise status block. Designed to catch recurring WSL2 and Git LFS issues before they derail a session.

1. **Worktree health** — `git worktree list --porcelain`; flags stale entries with Windows WSL gitdir paths and entries whose paths no longer exist on disk; runs `--dry-run` prune to show what would be removed (never prunes without confirmation)
2. **LFS hook check** — checks `.git/hooks/post-checkout` for `git lfs`; if present, flags that it will block `git worktree add` and offers the `--no-checkout` workaround
3. **Working tree state** — reports current branch name and whether the tree is clean
4. **Status summary** — one `[ok]` / `[warn]` / `[block]` line per check; outputs `preflight ok — no issues found` when everything passes

## Project Discovery

**Directory:** `plugin/skills/discover/`
**Triggered by:** `/mallet:discover`, "discover this project", "analyze the codebase"

Structured analysis of a project's codebase to identify setup opportunities:

1. **Scan** — languages, frameworks, build tools, structure
2. **Critical files** — inbound-reference count script identifies the highest-centrality modules (god nodes); reported with reference count and why they matter. Skipped for small projects.
3. **External services** — SDKs, auth providers, data services, observability
4. **Augmentation opportunities** — evaluated against `plugin/skills/discover/catalog.md`, which holds each tool's install command and recommend/skip signals: MCP servers (e.g., Context7 for libraries with live docs), skill packs (e.g., Impeccable for frontend UI work), CLI-Anything harnesses (pre-built `SKILL.md` wrappers for ~100+ desktop/server apps — recommended when the project interacts with design, media, GIS, or automation software), and code intelligence plugins (Anthropic's official language server plugins — one recommended per language in meaningful use, with whether its binary is already on `PATH`)
5. **Focused questions** via `AskUserQuestion` to resolve priorities
6. **Research** — WebSearch for confirmed services, propose concrete skills
7. **Skill and documentation opportunities** — including connection data, project conventions for `.mallet/conventions.md`, and patterns worth proposing back to the plugin
8. **Report** — saved to `.mallet/discovery-YYYY-MM-DD.md`
9. **Quick wins** — offer to implement high-value suggestions immediately

## Feature Planning

**Directory:** `plugin/skills/plan-feature/`
**Triggered by:** "plan a feature", "I want to build X", or "continue the Y feature"

Intake-to-execution pipeline. Supports resumption across sessions. All planning files are committed directly to the default branch so plans remain visible regardless of the active branch. `plans-worktree.sh` (next to the skill) resolves where: the current checkout when already on the default branch, otherwise a per-repository worktree inside `.git/mallet-plans` (or an existing worktree of the default branch). When `.mallet/` is ignored, plans stay local and nothing is committed. Commits always name their paths, so unrelated staged changes are never included.

1. **Pre-check** — reads existing plans from the default branch; surfaces overlaps before creating anything new
2. **Intake** — broad questions (problem, users, success criteria, constraints, remote system involvement)
3. **Design approval gate** — a one-paragraph design summary must be explicitly approved before decomposition begins; when the design commits to something expensive to reverse, offers to test it with `/mallet:council` first
4. **Knowledge skill assessment** — if the feature touches a domain with strong conventions (API design, auth, data modelling, security, accessibility, performance, domain rules), offers to scaffold a knowledge skill by copying `${CLAUDE_SKILL_DIR}/knowledge-skill-template.md` to `.mallet/skills/<domain>-knowledge/SKILL.md`
5. **Decompose** — confirms a slug; writes `plan.md`, `state.md`, and per-task stubs, each with a task-content discipline check (no TBD, every step names a concrete file or command)
6. **Execute (wave model)** — identifies tasks whose dependencies are satisfied (a wave); when parallel, dispatches each task to its own subagent so only results surface to the main context
7. **Resume** — loads `plan.md` and `state.md` from master, reading `state.md` first for prior decisions and blockers

## Implement Feature

**Directory:** `plugin/skills/implement-feature/`
**Triggered by:** "implement this feature", "add X functionality", or any non-trivial code change, including resuming an interrupted run

A thin launcher: this skill only collects inputs, launches the `feature-pipeline` workflow, and handles what a Workflow script cannot do itself — asking the user a question.

1. **Collect inputs** — feature description and test command (both required), working directory (default: project root), and three yes/no options defaulting to yes: plan critique, scope validation, code review
2. **Launch** — calls the Workflow tool (`feature-pipeline`, or `mallet:feature-pipeline` where namespaced) with `feature`, `testCommand`, `workingDir`, optional `context`, and the three booleans as `critique`/`scopeValidation`/`review`; `agentPrefix` defaults to `"mallet:"` and is set to `""` only when the personas are installed outside the plugin namespace
3. **Handle the result** — routes on the returned `status`/`stoppedAt`: `done` reports the run log and offers a PR; `blocked` at `spec` puts Frida's unknowns to the user and re-runs with `answers`; `blocked` at `plan` shows the remaining `amendments`; `blocked` at `implement`/`test`/`review` shows the blocker and waits for direction; `revise` at `validate` shows Sylvie's `gaps` and asks whether to re-plan or re-implement
4. **Resume** — an interrupted or re-run pipeline resumes via the Workflow tool's `resumeFromRunId`; completed agent calls return cached results and only the changed step onward re-runs

### The workflow itself

**File:** `plugin/workflows/feature-pipeline.js`

Runs the pipeline across seven named agents, each bound via `agentType: <agentPrefix><agent-name>`:

| Step | Agent | Role |
|---|---|---|
| 1. Spec | `feature-analyst` (Frida) | Turn the request into scope and acceptance criteria |
| 2. Plan | `code-analyst` (Callum) | Read the codebase, produce a change plan (locations, signatures, behaviour — not written-out code) with a planned test per acceptance criterion, each naming the regression it catches |
| 2b. Critique | `plan-critic` (Percy) | Challenge the plan against the spec, including criteria without a test |
| 3. Implement | `implementer` (Ingrid) | Apply the approved plan, tests included |
| 3b. Test | `test-runner` (Tobias) | Run the suite, return only signal |
| 3c. Validate | `scope-validator` (Sylvie) | Read the real change set from git, confirm acceptance criteria met, no scope creep; its git file list feeds review |
| 3d. Review | `code-reviewer` (Clifford) | Senior review — blocking vs non-blocking; checks consumers outside the diff, concurrency and trust boundaries, test quality, stale docs; lists what it declined to judge |

Every agent call is scored against a shared JSON contract (`status: approve|revise|blocked`, `summary`, `output`, `handoff`, `amendments`, `changedFiles`) so the orchestrator can route without free-text parsing. Iteration budgets: plan plus critique share 2 revisions; implement, test, and review share 2, with one revision cycle allotted to review specifically, after which Clifford re-reviews the fix, checking each previous blocking issue first; the last fix attempt the budget allows runs Ingrid on `opus`; a second blocking review ends the run as `blocked`. Any `blocked` result ends the run immediately and is returned to the launching skill — a Workflow script cannot pause and ask the user itself. There is no `.mallet/pipeline-state/` checkpoint file any more; resumption goes through the Workflow tool's own `resumeFromRunId` instead.

`/code-review` is not reachable from a script, which is why `code-reviewer` (Clifford) remains a dedicated review stage rather than delegating to the slash command.

## Architecture Decision Records

**Directory:** `plugin/skills/adr/`
**Triggered by:** "record this decision", "create an ADR", "document why we chose X", `/mallet:adr`, or during `plan-feature` when a significant architectural choice is made

Captures a significant architectural decision in Nygard format so the rationale survives beyond the session.

1. **Locate** — finds `docs/adr/` and determines the next four-digit number; creates the directory if it doesn't exist
2. **Gather** — extracts context, decision, alternatives, and consequences from the conversation; asks only for what's missing; for an undecided choice that is expensive to reverse, offers to run `council` first
3. **Write** — creates `docs/adr/NNNN-<title>.md` with Context, Decision, Alternatives Considered, and Consequences sections
4. **Index** — appends to (or creates) `docs/adr/README.md`
5. **Link** — offers to reference the ADR from an active feature plan or mission file
6. **Commit** — stages and commits with `Add ADR-NNNN: <title>.`

## Council

**Directory:** `plugin/skills/council/`
**Triggered by:** `/mallet:council`, "council this", "pressure-test this decision"; offered by `adr` and by `plan-feature`'s design gate, and run once the user agrees, when a decision is expensive to reverse

Tests a decision against four independent advisors before it is made. Each starts from a written brief in its own context rather than the conversation, so none inherits the framing or agreement built up in the session.

| Agent | Persona | Lens | Model / Effort |
|---|---|---|---|
| `council-contrarian` | Cassandra | What would make the decision fail | opus / high |
| `council-first-principles` | Felix | Whether it addresses the right problem, framed the right way | opus / high |
| `council-expansionist` | Esme | The upside and the options being missed, each with its cost | sonnet / high |
| `council-executor` | Ezra | The first concrete steps and what blocks them | sonnet / high |

1. **Brief** — question, context, every option including doing nothing, hard constraints, and what is settled; the chair's own leaning is kept out so it cannot anchor the advisors. The user confirms or corrects the brief before convening, since a wrong brief misleads all four advisors alike
2. **Convene** — all four in parallel with identical inputs; a failed advisor is re-dispatched once, and a lens still missing is named in the verdict
3. **Chair** — the main session verifies the claims that decide the outcome and weighs the answers rather than averaging them: the verdict follows the objections that hold, from any advisor, rather than the vote count; an objection that holds moves the verdict or is named as an accepted risk; shared-model agreement counts for less than it looks; a `reframe` is settled first; and the chair's own leaning is tested last. Output: verdict, strongest objection and whether it holds, upside worth its cost, first action, a per-advisor table, and what would change the verdict
4. **Record** — feeds an ADR when called from `adr`; otherwise offers one for an architectural decision, or leaves the summary in the conversation

Modelled on Karpathy's LLM Council, which polls different model vendors. Here the independence comes from separate contexts and lenses, with a mix of `opus` and `sonnet`; the anonymous peer-ranking round is left out, since it adds a second round of calls within one model family. Four subagent runs per council, so it is for decisions that are expensive to reverse.

## Checkpoint

**Directory:** `plugin/skills/checkpoint/`
**Triggered by:** "checkpoint", "save state", `/mallet:checkpoint`, or proactively before `/compact`

Persists in-progress session state so it survives compaction or a restart. No summary or reflection — write-only. Complements `reviewing-sessions` (checkpoint mid-session, wrap-up at the end).

1. **Memory** — saves anything not yet recorded to Claude Code's auto memory: corrections as `feedback` memories, non-obvious commands/conventions/quirks as `project`/`reference` memories; updates an existing memory rather than duplicating; skips anything already covered by a skill or the persona
2. **Mission state** — if work is clearly ongoing, writes or updates `.mallet/missions/active.md`; if that file already holds a *different* open mission, writes to `.mallet/missions/<short-name>.md` instead rather than overwriting it, and tells the user both are live
3. **Confirm** — one line per file written, or `Checkpoint: nothing new to persist.`

## Session Wrap-Up

**Directory:** `plugin/skills/reviewing-sessions/`
**Triggered by:** "wrap up", "all done", "end session"

Structured end-of-session retrospective. No session record files are written — skill and directive updates (step 4) do write to framework files.

1. **Session summary** — goal, approach, outcome
2. **What went well** — efficient tasks, effective patterns, good tool use
3. **What went poorly** — mistakes, user corrections, rule violations (with specific references)
3a. **Token efficiency** — flags patterns that drove unnecessary cost (long sessions without compaction, Write on existing files, verbose post-Bash responses, oversized subagents); proposes a persona/skill addition for any gap found
4. **Skill and directive improvements** — updates to skills based on session observations; skill backlog reviewed and actioned; **docs parity check** — any change to a skill or hook must reflect in the corresponding `docs/` section before the work counts as done
4a. **Review memory entries** — checks the auto memory entries written or updated this session; adds new ones only if something significant was missed
4b. **Mission state** — if the mission is complete, archives `active.md`; if work continues, writes or updates it, and if a *different* open mission already occupies it, consolidates deliberately or keeps this session's mission in its own file with a cross-reference
5. **Close out** — clear any scratchpad used; confirm the correct working branch; present the full wrap-up to the user

## Next Steps

**Directory:** `plugin/skills/next-steps/`
**Triggered by:** "what's pending", "what's left", "what's next", "next steps", `/mallet:next-steps`, or a request for the remaining work as a referenceable list

Reports outstanding work as a numbered table the user can refer to by number. Read-only except for step 6 — `checkpoint` writes state and `reviewing-sessions` reflects on the session, this one only reports what remains. Tracker-agnostic: it discovers what the environment has rather than assuming one exists, and degrades to mission files alone when a project has no tracker.

1. **Discover sources** — `.mallet/missions/*.md` (all of them, not just `active.md`), the current session, `.mallet/skill-backlog.md` and auto memory for deferred items; then whatever exists: a tracker MCP, `gh` issues and PRs, or a source named in `CLAUDE.md`/`conventions.md`/auto memory
2. **Collect** — pending mission items, work agreed but never written down, open tracker items belonging to the thread; excludes completed work and anything already in a `## Cleared` section
3. **Verify** — re-checks each referenced tracker item's real status and searches for items covering work recorded as untracked; cost-capped — never queries for item bodies, batches by identifier, `jq`s an overflow file rather than reading it back
4. **Table** — `# | What | Why | Effort | Relevant repo(s) | Tracked as`, ordered by readiness so dependencies stay visible. `Effort` is `Quick`/`Medium`/`Long`/`Unclear`, inferred only from signals already collected, never from fresh investigation. Untracked items say `None`, never blank and never invented
5. **Report coverage** — which sources were consulted, and which were unavailable, so the table's limits are visible
6. **Persist pruning** — when the user replies by number, pruned items move to a `## Cleared <date>` section of their mission file rather than being deleted, and the table is reissued renumbered

## Calibrate

**Directory:** `plugin/skills/calibrate/`
**Triggered by:** `/mallet:calibrate`, "check model for this", "is this the right model?", "what effort should I use?" — **manual-only**

The long-form version of the always-on Task Calibration directive (see [`directives.md`](directives.md#task-calibration)), for when the user asks directly.

1. **Establish the active setting** — model from the environment section (confirmed by a `[calibrate]` hook line if present); effort from `${CLAUDE_EFFORT}`; available models only from what the environment currently lists, never from memory
2. **Characterise the task** — judges the work itself against a signal table: lasting design decisions and security-sensitive logic point to higher effort or the most capable model; multi-file work with a clear spec fits the active model at `high`; mechanical/single-file work wants lower effort; very large inputs favour checking `/context` over a bigger model; many independent parts favour a Workflow over a bigger model; a bounded part whose difficulty differs from the rest of the session favours delegating it to a subagent on a suitable model
3. **Recommend** — a three-line block (`Active`, `Recommended`, `Why`); if the active setting already fits, says so in one line and stops. Delegating the part that needs a different model to a subagent is preferred over switching the session's model, which invalidates the prompt cache; `/model` is recommended only when most of the remaining work needs it. Only parts with a clear input and output are delegated, since the subagent starts without the conversation.

## Systematic Debugging

**Directory:** `plugin/skills/systematic-debugging/`
**Triggered by:** Debugging errors or unexpected behaviour; also after a failed fix attempt

Four-phase methodology enforcing root cause investigation before any fix.

1. **Root cause investigation** — reproduce consistently; read full error and trace; review recent changes; add diagnostic instrumentation; trace a deep failure backward to where the bad value originates; bisect the suite when a test fails only alongside others
2. **Pattern analysis** — locate a working analogue (if one exists); otherwise reason from first principles across touched dependencies
3. **Hypothesis and testing** — falsifiable hypothesis; one variable at a time; discard or refine on evidence
4. **Implementation** — write a failing test first (when behaviour is testable); apply a single targeted fix at the origin; validate at the boundary the bad value crossed; confirm pass and no regressions

Hard rule: no fix is applied before root cause is confirmed. Three consecutive failed fixes in different locations signals an architectural problem — stop and map the system rather than continue guessing. Signs from the user that Claude is guessing ("Stop guessing", "Is that not happening?") send it back to step 1. When a complete investigation finds the failure environmental or external, the skill's exit is to record what was ruled out, add handling (retry, timeout, clear error), and add logging for next time.

Includes a **condition-based waiting** pattern: replace arbitrary `sleep` delays in tests with polling for the actual condition (check every 10ms, timeout with a descriptive message). Eliminates flaky timing-dependent failures.

## Receiving Code Review

**Directory:** `plugin/skills/receiving-code-review/`
**Triggered by:** A code review is returned from any source (Clifford, human reviewer, PR feedback) and needs to be processed

Methodical framework for processing review feedback without performative compliance or uncritical acceptance.

1. **Understand completely** — read and classify all feedback (blocking / non-blocking) before acting on any item; ask about unclear items before fixing any
2. **Verify against reality** — confirm each flagged location and described behaviour matches the actual code before accepting the review as correct; say so when a claim cannot be verified
3. **Evaluate technically** — test each blocking item for correctness, functionality impact, context completeness, scope (YAGNI — grep whether the code is used before "implementing it properly"), and architectural fit; surface conflicts with a specific technical explanation rather than silently complying
4. **Respond factually** — describe the actual fix, not praise ("Changed guard at `auth.ts:42`" not "Great catch!"); push back technically when warranted; reply to inline GitHub comments in their thread
5. **Implement methodically** — locate, understand, apply targeted fixes; batch all blocking fixes before re-review

Hard rule: reviewer seniority does not override technical correctness. An incorrect fix applied under social pressure ships wrong code.

## Create PR

**Directory:** `plugin/skills/create-pr/`
**Triggered by:** "create PR", "open a PR", "make a pull request"
**Tools:** `allowed-tools` grants read-only git plus `gh pr view` (`git diff/log/status/rev-parse/symbolic-ref`, `gh pr view`) — a grant, not a restriction; the skill still pushes and creates the PR via ordinary `Bash`/`gh` calls after explicit confirmation

Generates a structured, non-technical PR summary (What Changed / Why / Customer Impact / Risk & Mitigation), pushes the branch with explicit confirmation, and opens the PR via `gh pr create`. The default branch is detected dynamically via `git symbolic-ref refs/remotes/origin/HEAD` — works with any main-branch convention (`master`, `main`, `trunk`, etc.).

## Write Task

**Directory:** `plugin/skills/write-task/`
**Triggered by:** creating a ticket, task, issue or sub-task in any tracker; writing or filling in a task description; writing a handover prompt "as a task" for another session or repository

The single home of Mallet's task format. Writes a task body a later session can complete without the originating conversation, using a fixed skeleton: `📋 OBJECTIVE` (Goal, Rationale), `🔍 CURRENT STATE` (Scope, Entry Points, Context Docs), `🎯 TARGET STATE` (a checklist of verifiable conditions), with no `---` dividers.

1. **Gather** — the outcome, the reason and its evidence, scope, entry points, related docs, and completion conditions; asks rather than guessing when the outcome or reason is unclear
2. **Draft** — fills the skeleton under two rule sets. Filling rules: intent rather than implementation (no line numbers, no spelled-out edits, no prescribed commit or deploy sequence), Entry Points as pointers only, Target State conditions as outcomes someone else can verify, evidence and its verification date in Rationale, incident-prone ordering as a Target State condition. Writing rules: no em or en dashes or arrow characters, no hyphenated compound modifiers in prose, periods on every sentence and bullet, no capital after a colon in a bullet
3. **Check** — re-reads the draft against both rule sets before showing it
4. **Confirm** — shows title and body and waits for confirmation; a text-only request (such as a handover prompt) ends here with the body in chat
5. **Create** — tracker-agnostic, following `next-steps`: finds the tracker from the tool list, `gh`, or project config, asks when several apply, and returns the body in chat when none does. Jira via REST or MCP needs ADF `taskList`/`taskItem` nodes for the checkboxes, since markdown `- [ ]` is stored as escaped literal text; GitHub issues and Linear take the markdown as is

---

## Harvest (project maintenance, not shipped)

**Directory:** `.mallet/skills/harvest/`
**Triggered by:** "harvest", "run harvest", or "harvest `<project-path>`"

Reviews a target project for improvements worth pulling back into the plugin base. Runs in the claude-mallet repo only — this is a project skill (see below), not part of `plugin/`.

1. **Pull check** — ensures this repo is up to date before comparing anything
2. **Project skills** — scans `TARGET/.mallet/skills/`; offers to promote selected skills into the base
3. **Overrides** — scans `TARGET/.mallet/overrides/`; surfaces each override with a summary and asks whether it reveals a gap worth folding into the base skill (overrides are project-specific by design and never auto-promoted)

Framework drift in the target is intentionally **not** addressed — local edits to plugin-managed files are overwritten on the next plugin update. If a target diverges, the clean path is an override, a project skill, or a direct PR to this repo.

## Knowledge Skill Template

**File:** `plugin/skills/plan-feature/knowledge-skill-template.md`
**Used by:** `plan-feature` when a feature domain warrants encoding expertise, referenced via `${CLAUDE_SKILL_DIR}`

Template for creating domain knowledge skills — skills that inject expertise (principles, decision rules, reference data, anti-patterns) rather than orchestrate a workflow. Copy to `.mallet/skills/<domain>-knowledge/SKILL.md` and fill in domain-specific content.

## Skill Backlog

**File:** `.mallet/skill-backlog.md` (created on demand)

Silent log of potential new skills or improvements captured during sessions. Reviewed during wrap-up.

## Project Skills

**Directory:** `.mallet/skills/` (optional)

Project-specific skills that sit alongside plugin skills but are not shipped to other projects and are not namespaced. Same `SKILL.md` format.

## Skill Overrides

**Directory:** `.mallet/overrides/` (optional, one file per overridden skill)

Per-skill amendments to base plugin skills, indexed via a "Skill Overrides" section in `.mallet/conventions.md`. Before executing a listed skill, Claude reads `.mallet/overrides/<skill-name>.md` and applies its contents as amendments — overrides win on conflict.

Override files are created and maintained by Claude on user request. Because the index lives in `.mallet/conventions.md` (already in context), Claude never probes the filesystem for absent overrides. See the [Skill Overrides section of Project Context](directives.md#project-context).

## Adding New Skills

1. Create `plugin/skills/<name>/SKILL.md`
2. Write a `description` that states **trigger conditions only** (when to invoke), not what the skill does
3. Add `disable-model-invocation: true` if the skill should only run when explicitly asked (setup, one-off toggles, destructive actions)
4. Reference the skill's own directory via `${CLAUDE_SKILL_DIR}` rather than a hardcoded path, so it resolves correctly inside the installed plugin
5. Add or update a `docs/skills.md` entry (this file) and, for anything with a script or hook interaction, a test under `tests/`
6. Commit; it ships to users on their next plugin update (or immediately, for anyone with auto-update enabled)
