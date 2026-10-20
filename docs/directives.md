# Directives

`plugin/persona/PERSONA.md` defines the behavioral rules Claude follows for every session. Plugins cannot ship a `CLAUDE.md`, so `plugin/hooks/persona.sh` injects this file as `SessionStart` context instead — on `startup`, `resume`, `clear`, and `compact`, since the latter two drop earlier context that would otherwise carry the persona with it.

The persona is short on purpose: 2,870 characters, measured at 971 input tokens per request (`claude -p` with and without the file appended, 2026-10-20; the previous 9,312-character persona measured 3,109). It states only what Claude Code's own system prompt does not. Each section stayed because the plugin eval in `plugin/evals/` (seven cases, run on Fable with a Sonnet judge, three runs per arm) measured a difference with it present, or because it carries a convention that native Claude Code has no opinion on. The eval write-up is `.mallet/eval-2026-10.md`.

## Directive Summary

| Section | Purpose | Measured effect (Δ with vs. without) |
|---|---|---|
| Evidence | Cite the evidence a claim rests on; never speculate about a resource from its name; flag uncertainty | `no-speculative-labels` +1.00 |
| Tone | Calm, no emoji or hype; apply a correction without restating it | `calm-tone` +0.22 (full persona: +0.33) |
| Tools | No stderr suppression; no Python where an executable exists; one script across many files; no `replace_all` on bare numbers; no leading variable assignments or shell arrays | not measured (conventions) |
| Scope and depth | Write only to the project being worked in; reuse before writing new code; handle failures where they occur | not measured (conventions) |
| Irreversible actions | Explicit confirmation before database mutations; say whether a remote target is known to be production before any side-effecting command | `implied-consent` +0.33; `production-ambiguity` +1.00 |
| Memory | `[tentative]`/`[firm]` on decisions; `[re-evaluate]` on workarounds for earlier model limits | not measured (conventions) |
| Session | Offer a wrap-up (`reviewing-sessions`) when a task reaches a natural end | not measured |

The control case (a plain git question) scored the same with and without the persona: no harm measured.

## Details

### Evidence

Back conclusions with the command, output, log excerpt, or metric they rest on, cited to files and line numbers; scale the depth to the task but never skip it. Never label infrastructure "legacy" or "old", guess a resource's purpose from its name, or assume which model, service, or protocol is in use. A name is a hypothesis: say what evidence would confirm it and check when possible. Flag uncertainty instead of proceeding on a guess. Without the persona Fable named `legacy-api` as the obsolete service in three of three runs; with it, three of three treated the name as a hypothesis and listed the checks first.

### Tone

No emoji, stacked exclamation marks, ALL CAPS, or hype words; emoji stay allowed in PR bodies and commit messages where they aid scanning. After the user rejects a tool call or corrects something, apply the fix without restating what went wrong.

### Tools

Five bullets that native Claude Code does not state: never suppress stderr with `2>/dev/null`; don't write Python for a task that has a dedicated executable, and ask before installing one; for analysis across many files write one script (shell, `jq`, or `awk` first) that prints only the result, and for large result sets fetch a compact index before detail; never `replace_all` a bare numeric literal in CSS, JS, or HTML; never start a Bash command with a variable assignment or use shell arrays, since permission allow-lists cannot match them.

### Scope and depth

When an issue spans several projects, write only to the one being worked in and propose the fix for the others. Before writing new code, take the first option that holds: what the codebase already has, then the standard library or a native platform feature, then an installed dependency. Handle failures where they can realistically occur (I/O, network, user input, external APIs), not where they cannot.

### Irreversible actions

Database mutations (UPDATE, DELETE, DROP, TRUNCATE, schema changes) need explicit confirmation after stating what will be destroyed and why; implied or contextual consent is not enough. Before any command with side effects on a remote host, service, or database, Claude says whether it knows that target is production, asks if it does not, treats a hostname, container name, or path as no evidence either way, states the impact of a restart, write, or config change, and prefers read-only investigation first. The earlier "Production Awareness" wording measured no effect; this wording scored +1.00 on `production-ambiguity`. File deletion and other destructive operations are no longer listed: native Claude Code already confirms those, and the eval measured no difference from restating it.

### Memory

Persistent facts live in Claude Code's auto memory, which needs no instruction from the persona. Two tagging conventions remain: significant decisions are marked `[tentative]` until confirmed, then `[firm]`; a workaround for an earlier model limitation that looks unnecessary is saved labelled `[re-evaluate]` rather than removed unilaterally.

### Session

When a task reaches a natural end, offer a wrap-up (`reviewing-sessions`).

## Git conventions

The persona carries no Git rules. They vary per project, and Claude Code loads a project's own `CLAUDE.md` and `.claude/rules/*.md` in every session and re-reads them after compaction, so a project file is the right home. Mallet ships its defaults as `plugin/rules/git.md`:

- Branch off the default branch for each task, or use a worktree; never commit to it directly.
- `b/<description>` for bug fixes, `f/<description>` for everything else; never reuse a branch from an earlier session.
- Commit, open a PR, switch back; never merge a PR without explicit instruction.
- A one-line subject with no body: imperative verb, capital first letter, ending with a period, e.g. `Add password reset email template.`; trailers such as `Co-Authored-By` below it.

`plugin/hooks/session-start.sh` checks on `startup`, `clear`, and `compact` whether the project already states Git conventions: a markdown heading naming Git as a word (`## Git`, `## Git workflow`) or the marker comment at the top of the rule file, in `CLAUDE.md`, `CLAUDE.local.md`, `.claude/CLAUDE.md`, or any `.md` under `.claude/rules/`, in the project directory, every directory above it, or `~/.claude/`. In a git repository where none exists, the hook prints the default rules for that session (221 tokens, measured) and asks Claude to offer once, after the first request is handled, to copy `${CLAUDE_PLUGIN_ROOT}/rules/git.md` to `.claude/rules/git.md`. A project that wants different rules writes its own Git section instead; either stops the notice. Mallet never writes the file without the user's agreement. The old persona's exception for `.mallet/features/` (feature plans committed to the default branch directly) is not in the rule file; `plan-feature` states it itself. Details of the check are in [`hooks.md`](hooks.md#session-start-hook).

This repository is its own example: the root `CLAUDE.md` has a `## Git` section (commit directly to `master`, no branches or PRs), so the check stays quiet here.

### Where directives come from

The persona loads in every session, in every project, once the plugin is installed — there is no per-project marker and nothing to remember. Project and user files layer on top, loaded by Claude Code itself:

| File | Scope | Loaded by |
|---|---|---|
| `plugin/persona/PERSONA.md` | every project | `plugin/hooks/persona.sh` on `SessionStart` |
| `<project>/CLAUDE.md`, `<project>/.claude/rules/*.md` | that project — the project's own files; the one Mallet offers to add is `.claude/rules/git.md`, on agreement | Claude Code |
| `~/.claude/CLAUDE.md`, `~/.claude/rules/*.md` | every project, for this user | Claude Code |
| `plugin/rules/git.md` | a git repository with no Git conventions of its own, for that session | `plugin/hooks/session-start.sh` |

Project conventions that used to live in `.mallet/conventions.md`, and skill amendments in `.mallet/overrides/`, are no longer read: the persona section that instructed it is gone (table below). Their content belongs in `CLAUDE.md` or `.claude/rules/<topic>.md`, which Claude Code loads without any instruction from Mallet; an amendment to a Mallet skill is `.claude/rules/<skill>.md` with "When running `/mallet:<skill>`, ..." lines. This repository's root `CLAUDE.md` points at its own `.mallet/conventions.md` explicitly, so that file still applies here.

### Directives removed 2026-10-20

The persona went from 9,312 to 2,870 characters. Each section below was dropped because Claude Code's own system prompt covers it, because the eval measured no effect from it, or because it instructed a mechanism that `.claude/rules/` or auto memory replaces.

| Removed | Why |
|---|---|
| Interaction Style (read proactively, ask about naming, push back with evidence, hold position) | Native system prompt covers each; `reviewer-claim` measured 1.00 with and without |
| Implementation Depth (solve completely, fix related fragile code, extract real duplication) | Native covers; the reuse-before-writing and failure-handling bullets were kept under Scope and depth |
| Destructive Operations beyond database mutations | Native confirms file deletion and discards; `implied-consent` measured equal until the persona was reduced to the database sentence |
| Production Awareness | Reworded into Irreversible actions; the old wording measured no effect, the new one +1.00 |
| Git Workflow | `plugin/rules/git.md` and the session-start check above |
| Memory and Self-Improvement (save `feedback` memories, what to save) | Native auto memory instructs this; only the `[tentative]`/`[firm]`/`[re-evaluate]` tags remain |
| Skills (check before every request, trigger-only descriptions, skill backlog) | Native loads skill descriptions and invokes on match; `.mallet/skill-backlog.md` is no longer written, and `reviewing-sessions` drains a leftover one |
| Verification Before Done | Native system prompt requires verification before reporting completion |
| Subagents | Native Agent tool guidance covers when and how to delegate |
| Task Calibration | The `[calibrate]` line from `user-prompt-submit.sh` is informational until that hook is removed |
| Continuity (missions, checkpoint, session-watch) | `session-start.sh` still flags an open mission and says what to do with it; `autoCompactWindow` in settings replaces session-watch; the wrap-up offer stays under Session |
| Project Context (`.mallet/conventions.md`, `.mallet/skills/`, Skill Overrides, skill routing) | `CLAUDE.md` and `.claude/rules/` are loaded natively; `.mallet/conventions.md` and `.mallet/overrides/` are no longer read; `session-start.sh` still lists `.mallet/skills/` |

### Directives removed in the move to a plugin

Several directives that duplicated a Claude Code built-in or an obsolete mechanism were dropped rather than carried forward, rather than kept as dead weight:

| Removed | Superseded by |
|---|---|
| Context Cache Design | No longer needed once dynamic content injection moved fully to hooks; nothing in the current persona edits the system prompt mid-session |
| Ultracode Mode | The Workflow tool is now used directly, without a keyword-triggered opt-in ritual |
| Project Memory (`.mallet/memory.md`) | Claude Code's own auto memory |
| Self-Improvement Loop (`.mallet/lessons.md`) | Auto memory `feedback` entries |
| Mandatory `task-calibrate` invocation on a hook flag | The renamed, manual-only `calibrate` skill, plus the reworked Task Calibration directive above |
| Several tool-preference bullets duplicated by the built-in system prompt, including "Format output as Markdown" | Not restated |
| Prefer Edit over Write | The `write-guard` hook, which blocks Write on existing files |
