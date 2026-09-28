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

- **Discovery (`/mallet:discover`)** — structured codebase analysis that surfaces setup opportunities: detected stacks and services, highest-centrality files (god nodes), MCP and skill-pack suggestions, conventions worth capturing, and quick wins Claude can implement immediately.
- **Session wrap-up (`/mallet:reviewing-sessions`, or "wrap up")** — end-of-session retrospective covering what went well, what went wrong, token-efficiency patterns, and applied improvements to skills and project memory.
- **Architecture decisions (`/mallet:adr`)** — captures significant architectural choices in Nygard format (`docs/adr/NNNN-title.md`) so the rationale survives beyond the session. Triggered automatically during feature planning when a significant choice is made.

## Installation

In Claude Code:

```
/plugin marketplace add dfsramos/claude-mallet
/plugin install mallet@claude-mallet
/mallet:setup
```

`/mallet:setup` handles what a plugin cannot configure on its own: registering the statusline (plugins can only set `agent`/`subagentStatusLine`, not the main `statusLine`), pointing you at enabling auto-update, and offering to fold any legacy `.mallet/memory.md` or `.mallet/lessons.md` into Claude Code's auto memory.

There is no version field: the plugin has no pinned release, so you track commits on the marketplace's default branch.

**Auto-update** is off by default for third-party marketplaces. Enable it via `/plugin` → **Marketplaces** → **claude-mallet** → **Enable auto-update**, or update on demand with `/plugin marketplace update claude-mallet`.

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
| `/mallet:migrate` | "clean up the old Mallet installs" |

Manual-only skills carry `disable-model-invocation: true` — Claude will not invoke them on its own; they run only when explicitly asked for.

### Agents

Sub-agents used by the `implement-feature` workflow, namespaced `mallet:<name>` at runtime:

| Agent | Persona | Role | Model / Effort |
|---|---|---|---|
| `code-analyst` | Callum | Reads the codebase, produces a change plan | sonnet / high |
| `plan-critic` | Percy | Challenges the plan against the spec | sonnet / high |
| `feature-analyst` | Frida | Turns a request into a structured spec | sonnet / high |
| `implementer` | Ingrid | Applies the approved plan | sonnet / high |
| `test-runner` | Tobias | Runs the test suite, returns only signal | haiku / low |
| `scope-validator` | Sylvie | Confirms acceptance criteria met, no scope creep | sonnet / high |
| `code-reviewer` | Clifford | Senior review — blocking vs non-blocking | sonnet / high |

Every review-only agent (all but `implementer`) is restricted to `disallowedTools: Edit, Write, NotebookEdit`.

### Workflow

`implement-feature` (`plugin/workflows/implement-feature.js`) runs the full spec → plan → critique → implement → test → validate → review pipeline as a single Workflow, launched by the `implement-feature` skill. Blocked results end the run and hand back to the launching skill, which asks the user and resumes via `resumeFromRunId`.

### Hooks

| Hook | Event | What it does |
|---|---|---|
| `persona.sh` | SessionStart (`startup\|resume\|clear\|compact`) | Injects `PERSONA.md` — the only way a plugin can deliver directives |
| `session-start.sh` | SessionStart (`startup`) | Refreshes the statusline copy in `${CLAUDE_PLUGIN_DATA}`; flags a leftover per-project install |
| `post-compact.sh` | SessionStart (`compact`) | Prints branch, uncommitted changes, recent commits, and any active mission right after compaction |
| `user-prompt-submit.sh` | UserPromptSubmit | Session-length warning at 50 and every 20 prompts after 80 (human-typed prompts only); injects the active model/effort line for calibrate when it changes |
| `write-guard.sh` | PreToolUse (`Write`) | Blocks `Write` on files that already exist — enforces `Edit` |
| `typecheck.sh` | PostToolUse (`Edit\|Write`) | Opt-in via `.mallet/typecheck.enabled`; runs `tsc`/`phpstan` and returns errors as JSON `additionalContext` |

For `PreToolUse`/`PostToolUse`/`PreCompact`, plain stdout only reaches the debug log, not the model — only `UserPromptSubmit` and `SessionStart` stdout is added to context. That is why `typecheck.sh` returns structured JSON and `write-guard.sh` writes its block reason to stderr with exit `2` instead of printing to stdout.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI with plugin support
- `bash`
- `jq`
- `git`

Node is not required — the `implement-feature` workflow runs through Claude Code's own Workflow tool, not a separate process.

## Documentation

- [Project Structure](docs/structure.md) — directory layout and file roles
- [Directives](docs/directives.md) — behavioral rules defined in the persona
- [Hooks](docs/hooks.md) — automatic actions triggered by Claude Code events
- [Skills](docs/skills.md) — reusable capabilities and the skill backlog
