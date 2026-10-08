# ClaudeMallet

<p align="center">
  <img src="assets/claude-mallet.jpg" alt="ClaudeMallet" width="400" />
</p>

> A mallet is the heavy, precise hammer a blacksmith uses to shape raw metal on the anvil — delivering controlled force to forge something strong and purposeful.
> ClaudeMallet is that tool for Claude Code: hammer in directives, hooks, skills, and a consistent persona, transforming raw Claude into a reliable, opinionated, and highly effective coding partner across every project.

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that customises agent behavior through a persona, hooks, skills, and a review-pipeline workflow.

## Overview

This repository is both a Claude Code plugin **marketplace** (`.claude-plugin/marketplace.json`) and the single plugin it hosts, `mallet` (`plugin/`). Installing the plugin gives every session, in every project, the Mallet persona, its skills and sub-agents, and its hooks — no per-project setup and nothing written into your repositories.

Plugins cannot ship a `CLAUDE.md`, so the persona (`plugin/persona/PERSONA.md`) is injected at session start by a hook instead (`plugin/hooks/persona.sh`), re-injected after `/clear` and `/compact` since those drop earlier context.

A project only gains a `.mallet/` directory when Mallet has something project-specific to store there — conventions, feature plans, mission state. Your repo's own `CLAUDE.md`, if it has one, is never touched.

Three workflows anchor the plugin and return the most value per session:

- **Discovery (`/mallet:discover`)** — structured codebase analysis that surfaces setup opportunities: detected stacks and services, highest-centrality files, suggested MCP servers, skill packs, and code-intelligence (LSP) plugins, conventions worth capturing, and quick wins Claude can implement immediately.
- **Session wrap-up (`/mallet:reviewing-sessions`, or "wrap up")** — end-of-session retrospective covering what went well, what went wrong, token-efficiency patterns, and applied improvements to skills and project memory.
- **Architecture decisions (`/mallet:adr`)** — captures significant architectural choices in Nygard format (`docs/adr/NNNN-title.md`) so the rationale survives beyond the session. Offered at `/mallet:plan-feature`'s design gate when the approved design makes a significant architectural choice.

## Installation

In Claude Code:

```
/plugin marketplace add dfsramos/claude-mallet
/plugin install mallet@claude-mallet
/mallet:setup
```

`/mallet:setup` handles what a plugin cannot configure on its own: registering the statusline (plugins can only set `agent`/`subagentStatusLine`, not the main `statusLine`), offering to turn on auto-update, and offering to fold any legacy `.mallet/memory.md` or `.mallet/lessons.md` into Claude Code's auto memory.

There is no version field: the plugin has no pinned release, so you track commits on the marketplace's default branch. [CHANGELOG.md](CHANGELOG.md) lists what each update changes, newest first.

**Auto-update** is off by default for third-party marketplaces. `/mallet:setup` offers to turn it on; otherwise use `/plugin` → **Marketplaces** → **claude-mallet** → **Enable auto-update**, or set `"autoUpdate": true` on the marketplace's `extraKnownMarketplaces` entry in `~/.claude/settings.json` (see [install.md](install.md)). Without it, update on demand with `/plugin marketplace update claude-mallet`.

## Moving from the user-level install

Earlier versions of Mallet installed directly into `~/.claude/` (skills, agents, hooks, a `CLAUDE.md`, `framework.json`). If that describes your machine, the transition is a single step:

**If you still have the old `update` skill**, say "update the framework" once more. It runs this repo's `install-payload.sh` and `merge-settings.sh` exactly as before, but those scripts now transition the install instead of updating it, and print the three commands above at the end.

**Manual equivalent**, if the skill is already gone:

```bash
curl -sfL https://github.com/dfsramos/claude-mallet/archive/refs/heads/master.tar.gz | tar -xz -C /tmp
bash /tmp/claude-mallet-master/.claude/install-payload.sh \
  --from /tmp/claude-mallet-master --repo dfsramos/claude-mallet --sha "$(git ls-remote https://github.com/dfsramos/claude-mallet master | cut -f1)"
bash /tmp/claude-mallet-master/.claude/merge-settings.sh \
  /tmp/claude-mallet-master/.claude/settings.fragment.json
```

Then run the three `/plugin` commands above.

What the transition does:

| Action | Detail |
|---|---|
| Backs up first | `~/.claude/mallet-pretransition-backup-<timestamp>.tar.gz` |
| Removes | only the skills/agents/templates/hooks entries `framework.json`'s manifest says Mallet installed |
| Removes | `~/.claude/statusline.sh`, but only if it is still Mallet's |
| Removes | `~/.claude/CLAUDE.md`, but only if it is byte-identical (ignoring line endings) to the installed version's own copy |
| Keeps | anything you authored yourself under `skills/`, `agents/`, `hooks/`, `templates/` |
| Keeps | a modified `~/.claude/CLAUDE.md` — and warns that the persona will now load twice unless you remove Mallet's sections from it yourself (the backup has the original for reference) |
| Leaves | a `~/.claude/skills/migrate/` stub (`detect.sh` + a marker file) so an in-progress `update` run finishes cleanly; `/mallet:setup` offers to remove it once the plugin is installed |
| Marks | `framework.json` as transitioned, so re-running the same script a second time is a no-op |

One follow-up to check yourself: a **project-level** hook registration pointing at `~/.claude/hooks/typecheck.sh` breaks after the transition, since that script no longer exists there. `/mallet:hooks-setup` detects and offers to remove it.

## Moving from a per-project install

Even older Mallet versions installed into each repository individually. The `migrate` skill still handles cleaning those up — say "clean up the old Mallet installs" or run `/mallet:migrate`. It moves each repo's state into `.mallet/`, removes only the untracked framework payload, leaves every git-tracked file alone, and takes a backup per repo before touching anything. See [`docs/skills.md`](docs/skills.md#migrate) for the full mechanics.

## What's Included

### Skills

| Skill | Trigger |
|-------|---------|
| `/mallet:discover` | "discover this project", "analyze the codebase" |
| `/mallet:adr` | "record this decision", "create an ADR" |
| `/mallet:council` | "council this", "pressure-test this decision" |
| `/mallet:plan-feature` | "plan a feature", "I want to build X" |
| `/mallet:implement-feature` | "implement this feature", "add X functionality" |
| `/mallet:systematic-debugging` | Debugging errors or unexpected behaviour |
| `/mallet:reviewing-sessions` | "wrap up", "end session" |
| `/mallet:checkpoint` | "checkpoint", "save state", or proactively before `/compact` |
| `/mallet:calibrate` *(manual-only)* | "check model for this", "what effort should I use?" |
| `/mallet:hooks-setup` *(manual-only)* | "set up hooks", "enable typecheck" |
| `/mallet:setup` *(manual-only)* | Right after installing the plugin |
| `/mallet:preflight` | Environment issues suspected before git-heavy work |
| `/mallet:create-pr` | "create PR", "open a PR" |
| `/mallet:receiving-code-review` | A code review has just been returned |
| `/mallet:next-steps` | "what's left", "what's next" |
| `/mallet:write-task` | "create a ticket", "write the task description", "write a handover as a task" |
| `/mallet:migrate` | "clean up the old Mallet installs" |

Manual-only skills carry `disable-model-invocation: true` — Claude will not invoke them on its own; they run only from their slash command.

### Agents

Sub-agents, namespaced `mallet:<name>` at runtime. These are used by the `feature-pipeline` workflow:

| Agent | Persona | Role | Model / Effort |
|---|---|---|---|
| `code-analyst` | Callum | Reads the codebase, produces a change plan | opus / high |
| `plan-critic` | Percy | Challenges the plan against the spec | opus / high |
| `feature-analyst` | Frida | Turns a request into a structured spec | sonnet / high |
| `implementer` | Ingrid | Applies the approved plan | sonnet / high (opus on the last fix attempt) |
| `test-runner` | Tobias | Runs the test suite, returns only signal | haiku / low |
| `scope-validator` | Sylvie | Confirms acceptance criteria met, no scope creep | sonnet / high |
| `code-reviewer` | Clifford | Senior review — blocking vs non-blocking | opus / high |

The `council` skill convenes four advisors, each starting from the same written brief in its own context:

| Agent | Persona | Lens | Model / Effort |
|---|---|---|---|
| `council-contrarian` | Cassandra | What would make the decision fail | opus / high |
| `council-first-principles` | Felix | Whether it addresses the right problem | opus / high |
| `council-expansionist` | Esme | The upside and the options being missed | sonnet / high |
| `council-executor` | Ezra | The first concrete steps and what blocks them | sonnet / high |

Every agent except `implementer` is restricted to `disallowedTools: Edit, Write, NotebookEdit`.

### Workflow

`feature-pipeline` (`plugin/workflows/feature-pipeline.js`) runs the full spec → plan → critique → implement → test → validate → review pipeline as a single Workflow, launched by the `implement-feature` skill. Blocked results end the run and hand back to the launching skill, which asks the user and resumes via `resumeFromRunId`.

### Hooks

| Hook | Event | What it does |
|---|---|---|
| `persona.sh` | SessionStart (`startup\|resume\|clear\|compact`) | Injects `PERSONA.md` — the only way a plugin can deliver directives |
| `session-start.sh` | SessionStart (`startup\|clear\|compact`) | On startup, refreshes the statusline copy in `${CLAUDE_PLUGIN_DATA}` and flags a leftover per-project install; lists `.mallet/skills/` project skills; flags an open mission with pending tasks |
| `post-compact.sh` | SessionStart (`compact`) | Prints branch, uncommitted changes, recent commits, and any active mission right after compaction |
| `user-prompt-submit.sh` | UserPromptSubmit | Compaction reminder when context reaches 150k tokens and at each further 50k (`CLAUDE_CTX_WARN_THRESHOLD` / `CLAUDE_CTX_WARN_STEP`); injects the active model/effort line for calibrate when it changes |
| `write-guard.sh` | PreToolUse (`Edit\|Write`) | Blocks `Write` on files that already exist — enforces `Edit`; asks before edits to lint or type-check config |
| `command-guard.sh` | PreToolUse (`Bash`) | Opt-in via `.mallet/command-guard.enabled`; denies git hook bypasses and force-pushing the default branch, asks before other destructive commands |
| `typecheck.sh` | PostToolUse (`Edit\|Write`) | Opt-in via `.mallet/typecheck.enabled`; records edited TypeScript/PHP files |
| `typecheck-stop.sh` | Stop | Opt-in, same marker; runs `tsc`/`phpstan` once per turn and returns errors in that turn's files as JSON `additionalContext` |

For `PreToolUse`/`PostToolUse`/`PreCompact`, plain stdout only reaches the debug log, not the model — only `UserPromptSubmit` and `SessionStart` stdout is added to context. That is why the guards answer with a JSON `permissionDecision`, `typecheck-stop.sh` returns JSON `additionalContext`, and `write-guard.sh` writes its Write block reason to stderr with exit `2` instead of printing to stdout.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI with plugin support
- `bash`
- `jq`
- `git`

Node is not required — the `feature-pipeline` workflow runs through Claude Code's own Workflow tool, not a separate process.

## Documentation

- [Project Structure](docs/structure.md) — directory layout and file roles
- [Directives](docs/directives.md) — behavioral rules defined in the persona
- [Hooks](docs/hooks.md) — automatic actions triggered by Claude Code events
- [Skills](docs/skills.md) — reusable capabilities and the skill backlog
