# Skills

Skills are reusable capabilities defined as `SKILL.md` files inside `plugin/skills/`, shipped with the `mallet` plugin and available in every project once it is installed. They are namespaced at runtime — `/mallet:<name>`, and agent type `mallet:<name>` for the sub-agents. A project can add its own in `.claude/skills/`, which Claude Code loads itself; those are not namespaced and not part of the plugin.

Skills marked **manual-only** below carry `disable-model-invocation: true` in their frontmatter: Claude will not invoke them on its own judgment; they run only from their slash command, so their descriptions name the command rather than trigger phrases.

## Setup

**Directory:** `plugin/skills/setup/`
**Triggered by:** `/mallet:setup` (or `/setup`), right after installing the plugin or to install the Mallet statusline — **manual-only**

One-time setup for what a plugin cannot configure by itself. Each step is independent — the user can decline any of them — and the skill reports what was done at the end.

1. **Statusline** — plugins cannot set the main `statusLine` (only `agent`/`subagentStatusLine` settings take effect), so this copies `${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh` to `${CLAUDE_PLUGIN_DATA}/statusline.sh` and points `~/.claude/settings.json`'s `statusLine` at that copy, backing the settings file up first and asking before replacing an existing non-Mallet `statusLine`
2. **Auto-update** — offers to turn on background auto-update, which is off by default for third-party marketplaces, by setting `extraKnownMarketplaces["claude-mallet"].autoUpdate` to `true` in `~/.claude/settings.json`. It keeps the marketplace's existing `source`, taken from that entry or from `~/.claude/plugins/known_marketplaces.json`, so a fork or local path is not overwritten. It backs up the file first and checks the result with `jq`. If no source can be found or the user declines, it gives the manual routes (`/plugin` → Marketplaces → claude-mallet → Enable auto-update, or `/plugin marketplace update claude-mallet` on demand)
3. **Report** — one line per step: done, skipped, or not applicable

## Feature Planning

**Directory:** `plugin/skills/plan-feature/`
**Triggered by:** "plan a feature", "I want to build X", or "continue the Y feature"

Intake-to-execution pipeline. Supports resumption across sessions. All planning files are committed directly to the default branch so plans remain visible regardless of the active branch. `plans-worktree.sh` (next to the skill) resolves where: the current checkout when already on the default branch, otherwise a per-repository worktree inside `.git/mallet-plans` (or an existing worktree of the default branch). When `.mallet/` is ignored, plans stay local and nothing is committed. Commits always name their paths, so unrelated staged changes are never included.

1. **Pre-check** — reads existing plans from the default branch; surfaces overlaps before creating anything new
2. **Intake** — broad questions (problem, users, success criteria, constraints, remote system involvement)
3. **Design approval gate** — a one-paragraph design summary must be explicitly approved before decomposition begins; when the design commits to something expensive to reverse, offers to test it with `/mallet:council` first; once approved, a design with a significant architectural choice (database, framework, communication pattern, key library) gets an offer to record it with `/mallet:adr`
4. **Knowledge skill assessment** — if the feature touches a domain with strong conventions (API design, auth, data modelling, security, accessibility, performance, domain rules), offers to scaffold a knowledge skill by copying `${CLAUDE_SKILL_DIR}/knowledge-skill-template.md` to `.claude/skills/<domain>-knowledge/SKILL.md`, where Claude Code loads it itself
5. **Decompose** — confirms a slug; writes `plan.md`, `state.md`, and per-task stubs, each with a task-content discipline check (no TBD, every step names a concrete file or command)
6. **Execute (wave model)** — identifies tasks whose dependencies are satisfied (a wave); when parallel, dispatches each task to its own subagent so only results surface to the main context
7. **Resume** — loads `plan.md` and `state.md` from master, reading `state.md` first for prior decisions and blockers

## Architecture Decision Records

**Directory:** `plugin/skills/adr/`
**Triggered by:** "record this decision", "create an ADR", "document why we chose X", `/mallet:adr`, or accepting the ADR offer at `plan-feature`'s design gate

Captures a significant architectural decision in Nygard format so the rationale survives beyond the session.

1. **Locate** — finds `docs/adr/` and determines the next four-digit number; creates the directory if it doesn't exist
2. **Gather** — extracts context, decision, alternatives, and consequences from the conversation; asks only for what's missing; for an undecided choice that is expensive to reverse, offers to run `council` first
3. **Write** — creates `docs/adr/NNNN-<title>.md` with Context, Decision, Alternatives Considered, and Consequences sections
4. **Index** — appends to (or creates) `docs/adr/README.md`
5. **Link** — offers to reference the ADR from an active feature plan
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

## Session Wrap-Up

**Directory:** `plugin/skills/reviewing-sessions/`
**Triggered by:** "wrap up", "all done", "end session"

Structured end-of-session retrospective. No session record files are written — skill and rule fixes (step 4) and auto memory entries (steps 4a and 4b) are the only writes.

0. **Recover the full session** — only when the session was compacted or its start is out of context: reads the session's own transcript (`~/.claude/projects/*/${CLAUDE_SESSION_ID}.jsonl`) through `jq`, keeping user prompts, assistant text, and tool-call names, capped at 400 lines; longer sessions are sampled and the sample is named
1. **Session summary** — goal, approach, outcome
2. **What went well** — efficient tasks, effective patterns, good tool use
3. **What went poorly** — mistakes, user corrections, rule violations (with specific references)
3a. **Token efficiency** — flags patterns that drove unnecessary cost (large output pulled into context where a filtered view would do, Write on existing files, verbose post-Bash responses, oversized subagents); saves a `feedback` memory for any gap no directive or memory covers
4. **Skill and rule improvements** — project and personal skills are edited directly, and new project skills go to `.claude/skills/`; a Mallet skill is never edited (the plugin cache is overwritten on update) but amended through `.claude/rules/<name>.md`, proposed to the user and written on agreement, with a proposed upstream change if it would help every project; project rules go to `.claude/rules/<topic>.md` or `CLAUDE.md`, proposed first since both are usually shared with a team, and rules for every project become `feedback` memories; each rule keeps one home, so an existing rule is amended where it lives rather than copied; a leftover `.mallet/skill-backlog.md` is actioned, pruned, and deleted once empty
4a. **Review memory entries** — checks the auto memory entries written or updated this session; adds new ones only if something significant was missed
4b. **Continuing work** — work that continues in a later session gets one auto memory `project` entry named after the goal (purpose, done, pending, blocked, decisions with their `[firm]`/`[tentative]` tags), updated rather than duplicated, terse enough to act on cold, and closed out once the goal is reached; a leftover `.mallet/missions/active.md` from an earlier Mallet version is folded into that entry, then archived under `.mallet/missions/archive/` or deleted on agreement
5. **Close out** — confirm the correct working branch; present the full wrap-up to the user

## Next Steps

**Directory:** `plugin/skills/next-steps/`
**Triggered by:** "what's pending", "what's left", "what's next", "next steps", `/mallet:next-steps`, or a request for the remaining work as a referenceable list

Reports outstanding work as a numbered table the user can refer to by number. Read-only except for step 6 — `reviewing-sessions` records continuing work, this one only reports what remains. Tracker-agnostic: it discovers what the environment has rather than assuming one exists, and degrades to auto memory and the session alone when a project has no tracker.

1. **Discover sources** — auto memory (the `project` entries where `reviewing-sessions` records continuing work, and any deferred item), the current session, and any leftover `.mallet/missions/*.md` (all of them, not just `active.md`) or `.mallet/skill-backlog.md` from an earlier Mallet version; then whatever exists: a tracker MCP, `gh` issues and PRs, or a source named in `CLAUDE.md`, `.claude/rules/`, or auto memory
2. **Collect** — pending items from memory entries or a leftover mission file, work agreed but never written down, open tracker items belonging to the thread; excludes completed work and anything already recorded as cleared
3. **Verify** — re-checks each referenced tracker item's real status and searches for items covering work recorded as untracked; cost-capped — never queries for item bodies, batches by identifier, `jq`s an overflow file rather than reading it back
4. **Table** — `# | What | Why | Effort | Relevant repo(s) | Tracked as`, ordered by readiness so dependencies stay visible. `Effort` is `Quick`/`Medium`/`Long`/`Unclear`, inferred only from signals already collected, never from fresh investigation. Untracked items say `None`, never blank and never invented
5. **Report coverage** — which sources were consulted, and which were unavailable, so the table's limits are visible
6. **Persist pruning** — when the user replies by number, pruned items are recorded as cleared where they came from (a `Cleared <date>:` line in the memory entry, or a `## Cleared <date>` section of a leftover mission file) rather than deleted, and the table is reissued renumbered

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

**Directory:** `.claude/skills/harvest/`
**Triggered by:** "harvest", "run harvest", or "harvest `<project-path>`"

Reviews a target project for improvements worth pulling back into the plugin base. Runs in the claude-mallet repo only — this is a project skill (see below), not part of `plugin/`.

1. **Pull check** — ensures this repo is up to date before comparing anything
2. **Project skills** — scans `TARGET/.claude/skills/` (and a leftover `TARGET/.mallet/skills/`, which nothing lists any more); offers to promote selected skills into the base
3. **Skill amendments** — scans `TARGET/.claude/rules/*.md` for "When running `/mallet:<skill>`" lines (and a leftover `TARGET/.mallet/overrides/`, no longer read); surfaces each amendment with a summary and asks whether it reveals a gap worth folding into the base skill (amendments are project-specific by design and never auto-promoted)

Framework drift in the target is intentionally **not** addressed — local edits to plugin-managed files are overwritten on the next plugin update. If a target diverges, the clean path is an amendment in `.claude/rules/`, a project skill, or a direct PR to this repo.

## Self-Assessment (project maintenance, not shipped)

**Directory:** `.claude/skills/self-assessment/`
**Triggered by:** a request for a self-assessment, critical assessment, health check, or audit of Mallet, in this repo

Critically reviews the plugin and this repo, verifies findings, and fixes them in groups. A project skill, not part of `plugin/`.

1. **Baseline**: runs the full suite first
2. **Fan out**: four read-only reviewers in parallel, covering persona and directives, skills and agents, executable code, and repo health
3. **Verify**: checks each high-severity or change-driving claim against the code, the Claude Code docs, the `bash:3.2` Docker image, or `git ls-remote` before it is reported; unchecked claims are marked unverified
4. **Report**: one ranked table plus suggested fix groups, with decisions that are the user's last
5. **Fix by group**: per group, a test proven to fail against the `HEAD` version, a bash 3.2 run for hook and statusline changes, docs parity, a `CHANGELOG.md` entry for user-visible changes, the full suite, an independent `mallet:code-reviewer` pass, then a commit to `master`
6. **Close out**: commits, findings that proved wrong, and what is left for the user

## Knowledge Skill Template

**File:** `plugin/skills/plan-feature/knowledge-skill-template.md`
**Used by:** `plan-feature` when a feature domain warrants encoding expertise, referenced via `${CLAUDE_SKILL_DIR}`

Template for creating domain knowledge skills — skills that inject expertise (principles, decision rules, reference data, anti-patterns) rather than orchestrate a workflow. Copy to `.claude/skills/<domain>-knowledge/SKILL.md` and fill in domain-specific content.

## Skill Backlog

**File:** `.mallet/skill-backlog.md` (no longer written as of 2026-10-20)

Earlier versions of the persona logged skill ideas here silently. The Skills section that did so is gone from the persona; where the file still exists, `reviewing-sessions` step 4 actions or removes its items and deletes it once empty. This repo's own was drained and deleted the same day.

## Project Skills

**Directory:** `.claude/skills/` (optional)

Project-specific skills that sit alongside plugin skills but are not shipped to other projects and are not namespaced. Same `SKILL.md` format; Claude Code discovers them itself. Earlier Mallet versions used `.mallet/skills/`, which session start listed for Claude; since 2026-10-20 nothing lists it, so a skill still there should move to `.claude/skills/`.

## Skill Overrides

**Removed 2026-10-20.** `.mallet/overrides/<skill>.md` and the "Skill Overrides" list in `.mallet/conventions.md` are no longer read: the persona's Project Context section, which instructed it, is gone. A project amendment to a Mallet skill now lives in `.claude/rules/<skill>.md` as "When running `/mallet:<skill>`, ..." lines, which Claude Code loads in every session without any instruction from Mallet. Move any existing override there. See [Where directives come from](directives.md#where-directives-come-from).

## Removed Skills

Removed 2026-10-20, each because native Claude Code or an official plugin does the job, or because nothing used it:

| Skill | Replacement |
|---|---|
| `discover` | `/init` writes a project's `CLAUDE.md`; `/doctor` and `/fewer-permission-prompts` cover the setup checks; the official `claude-code-setup` plugin suggests hooks, skills and MCP servers for a codebase |
| `checkpoint` | `/rewind` restores earlier state within a session; auto memory carries work across sessions, written by `reviewing-sessions` step 4b |
| `calibrate` | Nothing; the Task Calibration directive and the `[calibrate]` hook line it built on are gone |
| `preflight` | Nothing; its checks (stale worktrees, Git LFS hooks) were never invoked in 30 days of sessions and `systematic-debugging` covers an actual failure |
| `hooks-setup` | Nothing to toggle: the opt-in hooks it managed are gone (see [`hooks.md`](hooks.md#removed-hooks)) |
| `implement-feature`, with the `feature-pipeline` workflow and the agents `feature-analyst`, `code-analyst`, `plan-critic`, `implementer`, `test-runner` | Unused in 30 days of sessions. `code-reviewer` and `scope-validator` stay as standalone agents for Claude or the user to dispatch on a change set |
| `migrate` (removed 2026-10-21) | Nothing: every known user has moved to the plugin, so the per-project cleanup it did, and the user-level transition scripts this repo carried for it, had no one left to serve. `.mallet/.migration-declined` is inert; the session-start leftover-files notice names it for deletion |

## Adding New Skills

1. Create `plugin/skills/<name>/SKILL.md`
2. Write a `description` that states **trigger conditions only** (when to invoke), not what the skill does
3. Add `disable-model-invocation: true` if the skill should only run when explicitly asked (setup, one-off toggles, destructive actions)
4. Reference the skill's own directory via `${CLAUDE_SKILL_DIR}` rather than a hardcoded path, so it resolves correctly inside the installed plugin
5. Add or update a `docs/skills.md` entry (this file) and, for anything with a script or hook interaction, a test under `tests/`
6. Commit; it ships to users on their next plugin update (or immediately, for anyone with auto-update enabled)
