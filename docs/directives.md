# Directives

The root `CLAUDE.md` defines behavioral rules that Claude Code follows for every interaction in the project. These directives are loaded automatically when Claude Code opens the project.

## Directive Summary

| Directive | Purpose |
|---|---|
| Evidence-Based Approach | Require proof with every conclusion; never speculate |
| Communication Style | Calm, concise, Markdown-formatted, no hype |
| Interaction Style | Proactive reads, run commands instead of suggesting them |
| Tool Preferences | Prefer dedicated tools over Bash for file operations |
| Scope of Changes | Only write to the project being worked in unless explicitly asked |
| Destructive Operations | Never delete/overwrite without explicit confirmation |
| Production Awareness | Stop and confirm before acting on live environments |
| Git Workflow | Branch off `master`, open PRs, never commit directly |
| Self-Improvement Loop | Log corrections to `lessons.md`; apply them throughout the session |
| Verification Before Done | Run proof before claiming any task complete |
| Elegance Check | Pause before presenting non-trivial changes and ask if there's a cleaner approach |
| Skill Authoring | Skill `description` fields state trigger conditions only, not workflow summaries |
| Skill Backlog | Watch for reusable patterns and log them to `.claude/project/skill-backlog.md` |
| Project Context | Read `.claude/project/CLAUDE.md` at session start if it exists |
| Skill Overrides | Apply project-specific amendments to base skills via `.claude/project/overrides/<skill>.md` |
| Project Memory | Accumulate project-specific facts in `.claude/project/memory.md` across sessions |
| Mission Continuity | Read `.claude/project/missions/active.md` at session start; write one for multi-session work |
| Subagent Context Isolation | Use subagents to contain large intermediate output, not just for parallelism |
| Context Cache Design | Inject dynamic content via hooks; never edit the system prompt mid-session |
| Task Calibration | Mandatory invocation of `task-calibrate` on UserPromptSubmit complexity reminder |
| Session Closure | Proactively offer a wrap-up when a task concludes |

## Details

### Evidence-Based Approach

All conclusions must be backed by evidence. The depth scales with the task: forensic-level investigation for debugging, lighter verification for routine development. Speculation is never acceptable — if a claim cannot be supported by API output, config files, or code, it should not be made.

### Communication Style

Output is calm, measured, and formatted as Markdown. No ALL CAPS, excessive punctuation, or emoji. Facts are stated clearly with supporting evidence.

Exception: emojis are allowed in PR bodies and commit messages, where scannability aids non-technical readers.

### Interaction Style

Claude reads files and runs commands proactively instead of asking whether it should. User input is only requested when a decision genuinely requires their judgment.

### Tool Preferences

Dedicated tools (Read, Edit, Write, Grep, Glob) are preferred over Bash for file operations. Python scripts are not used when a dedicated executable exists for the task. When a command returns large output and only a subset is needed, it is piped through `jq`, `grep`, `head`, or a similar filter in the same Bash call — raw bulk output is never passed into the context window.

Edit is always preferred over Write. Write is only used when creating a file that does not yet exist. For any existing file — even when replacing most of its content — Edit is used instead.

Bash commands must never begin with a variable assignment (`TMPDIR="..." command`) or use shell arrays. Claude Code's permission system cannot match these patterns against its allow-list and will prompt for approval instead of auto-approving. Use literal paths throughout.

After a Bash command executes, the output is not summarised or restated unless the user asked for an explanation. If the result is self-evident, Claude proceeds directly to the next step.

### Scope of Changes

When diagnosing an issue that spans multiple projects or directories, Claude writes only to the project being actively worked in. Fixes for other locations are proposed and described, then left for the user to apply or to explicitly approve first.

### Destructive Operations

Any operation that cannot be trivially undone (deleting files, database mutations, overwriting data) requires explicit user confirmation before execution.

### Production Awareness

Before executing any operation, Claude assesses whether the target is a production environment. If ambiguous, it stops and asks before proceeding.

### Git Workflow

All changes go through branches off `master` — or an isolated git worktree for work that must not disturb the current branch. Branches follow a two-prefix convention: `b/<description>` for bug fixes and `f/<description>` for everything else (features, refactors, docs). Branches are not reused across sessions; each new session starts a fresh one. Commits are never made directly to `master`, and PRs are never merged without explicit user instruction.

One exception: files under `.claude/features/` are committed directly to `master` via a git worktree so that feature plans remain visible across every branch. This behaviour is owned by the `plan-feature` skill.

Commit messages are one line: imperative verb, capital first letter, ends with a period. Example: `Add password reset email template.`

### Project Context

If `.claude/project/CLAUDE.md` exists in the current project, Claude reads it at the start of every session. It contains project-specific conventions, stack details, and service context that extend the base directives without modifying them.

If `.claude/project/skills/` exists, it is treated as an additional skills directory alongside `.claude/skills/`. Skills there are available for use but are project-specific and not part of the base framework.

### Skill Overrides

Projects can amend base skills without copying them wholesale. When `.claude/project/CLAUDE.md` contains a "Skill Overrides" section listing a skill by name, Claude reads `.claude/project/overrides/<skill-name>.md` before executing that skill and applies its contents as amendments — the override wins wherever it conflicts with the base skill.

Override files are created and maintained by Claude at the user's request, never by hand. When the user asks to override part of a base skill, Claude writes the override file and adds the skill's entry to the Skill Overrides list in `.claude/project/CLAUDE.md` atomically. The list doubles as a registry: Claude only reads an override file if the list says one exists, so absent overrides cost nothing.

### Project Memory

`.claude/project/memory.md` is a persistent fact store for project-specific knowledge that accumulates across sessions. It holds things worth knowing but not worth formalising as a skill — preferred commands, gotchas, conventions, and tool preferences discovered through use.

Claude appends entries during sessions when it encounters something useful and audits them during the session wrap-up. The file is injected into context at session start by the session-start hook.

### Mission Continuity

When ongoing work is likely to span multiple sessions, Claude writes `.claude/project/missions/active.md` (handled by the `reviewing-sessions` skill). At the next session start, Claude reads the file and surfaces the pending tasks, asking the user whether to resume or start fresh. Missions are reserved for genuinely multi-session work — contained, single-session tasks do not warrant one.

### Self-Improvement Loop

After any correction from the user, Claude silently appends to `.claude/project/lessons.md`: what went wrong and the rule to prevent it recurring. If the file exists at session start, it is read and applied throughout the session.

When a constraint or workaround from a previous model's limitations looks obsolete, Claude tags the relevant lesson with `[re-evaluate]` rather than removing it. That flag is the signal to the user that the entry is a candidate for pruning; the user decides when to actually remove it.

### Verification Before Done

No task is marked complete without running the relevant proof: a test, a diff, or a command output. Claude asks itself "Would a staff engineer approve this?" before presenting the result.

### Elegance Check

For non-trivial changes, Claude pauses before presenting and asks whether there is a more elegant approach. If the current solution feels hacky, it implements the cleaner version instead. This check is skipped for simple, obvious fixes.

### Skill Authoring

The `description` field of any skill must state trigger conditions only — not what the skill does. Claude uses this field to decide when to activate the skill; a workflow summary does not serve that purpose. The template for knowledge skills lives at `.claude/templates/knowledge-skill/SKILL.md`.

### Skill Backlog

Claude watches for recurring patterns, recurring knowledge gaps, or reusable workflows that don't yet have a skill. When one is identified, it is silently appended to `.claude/project/skill-backlog.md` — title, what triggered it, brief description — without interrupting the session.

### Subagent Context Isolation

Subagents are used not only for parallelism but to contain sub-tasks whose intermediate state would otherwise pollute the main context. When a sub-task produces large intermediate output (raw search results, log analysis, code review) and only the synthesised conclusion is needed downstream, it is delegated to a subagent. Only the result surfaces in the main conversation.

When multiple sub-tasks are genuinely independent (no shared files, no sequential dependencies, no mid-task interactive decisions), they are dispatched to subagents in parallel — one tool call per task in a single message.

### Context Cache Design

Prompt caches are per-model and invalidate when the system prompt changes. To preserve cache hits, dynamic content (session ID, memory, reminders) is injected via hook stdout into the message stream — not by editing the system prompt mid-session. `<system-reminder>` tags are used for message injections. Models are not switched mid-session, as caches do not transfer across models.

### Task Calibration

When the UserPromptSubmit hook emits a `[task-calibrate]` reminder (complexity score ≥ 3), Claude must invoke the `task-calibrate` skill before responding. The reminder only fires on high-complexity prompts where model choice materially affects cost or quality, so invocation is mandatory rather than a soft nudge.

### Session Closure

When a task reaches a natural conclusion, Claude proactively offers a session wrap-up rather than waiting to be asked.
