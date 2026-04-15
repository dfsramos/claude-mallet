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
| Project Memory | Accumulate project-specific facts in `.claude/project/memory.md` across sessions |
| Long-Horizon Task Notes | Write intermediate findings to `task-notes.md` for multi-turn tasks |
| Subagent Context Isolation | Use subagents to contain large intermediate output, not just for parallelism |
| Context Cache Design | Inject dynamic content via hooks; never edit the system prompt mid-session |
| Session Closure | Proactively offer a wrap-up when a task concludes |

## Details

### Evidence-Based Approach

All conclusions must be backed by evidence. The depth scales with the task: forensic-level investigation for debugging, lighter verification for routine development. Speculation is never acceptable — if a claim cannot be supported by API output, config files, or code, it should not be made.

### Communication Style

Output is calm, measured, and formatted as Markdown. No ALL CAPS, excessive punctuation, or emoji. Facts are stated clearly with supporting evidence.

### Interaction Style

Claude reads files and runs commands proactively instead of asking whether it should. User input is only requested when a decision genuinely requires their judgment.

### Tool Preferences

Dedicated tools (Read, Edit, Write, Grep, Glob) are preferred over Bash for file operations. Python scripts are not used when a dedicated executable exists for the task. When a command returns large output and only a subset is needed, it is piped through `jq`, `grep`, `head`, or a similar filter in the same Bash call — raw bulk output is never passed into the context window.

Edit is always preferred over Write. Write is only used when creating a file that does not yet exist. For any existing file — even when replacing most of its content — Edit is used instead.

After a Bash command executes, the output is not summarised or restated unless the user asked for an explanation. If the result is self-evident, Claude proceeds directly to the next step.

### Scope of Changes

When diagnosing an issue that spans multiple projects or directories, Claude writes only to the project being actively worked in. Fixes for other locations are proposed and described, then left for the user to apply or to explicitly approve first.

### Destructive Operations

Any operation that cannot be trivially undone (deleting files, database mutations, overwriting data) requires explicit user confirmation before execution.

### Production Awareness

Before executing any operation, Claude assesses whether the target is a production environment. If ambiguous, it stops and asks before proceeding.

### Git Workflow

All changes go through branches. Commits are never made directly to `master`. PRs are opened for review and not merged without explicit instruction.

### Project Context

If `.claude/project/CLAUDE.md` exists in the current project, Claude reads it at the start of every session. It contains project-specific conventions, stack details, and service context that extend the base directives without modifying them.

If `.claude/project/skills/` exists, it is treated as an additional skills directory alongside `.claude/skills/`. Skills there are available for use but are project-specific and not part of the base framework.

### Project Memory

`.claude/project/memory.md` is a persistent fact store for project-specific knowledge that accumulates across sessions. It holds things worth knowing but not worth formalising as a skill — preferred commands, gotchas, conventions, and tool preferences discovered through use.

Claude appends entries during sessions when it encounters something useful and audits them during the session wrap-up. The file is injected into context at session start by the session-start hook.

### Self-Improvement Loop

After any correction from the user, Claude silently appends to `.claude/project/lessons.md`: what went wrong and the rule to prevent it recurring. If the file exists at session start, it is read and applied throughout the session.

### Verification Before Done

No task is marked complete without running the relevant proof: a test, a diff, or a command output. Claude asks itself "Would a staff engineer approve this?" before presenting the result.

### Elegance Check

For non-trivial changes, Claude pauses before presenting and asks whether there is a more elegant approach. If the current solution feels hacky, it implements the cleaner version instead. This check is skipped for simple, obvious fixes.

### Skill Authoring

The `description` field of any skill must state trigger conditions only — not what the skill does. Claude uses this field to decide when to activate the skill; a workflow summary does not serve that purpose. The template for knowledge skills lives at `.claude/templates/knowledge-skill/SKILL.md`.

### Skill Backlog

Claude watches for recurring patterns, recurring knowledge gaps, or reusable workflows that don't yet have a skill. When one is identified, it is silently appended to `.claude/project/skill-backlog.md` — title, what triggered it, brief description — without interrupting the session.

### Long-Horizon Task Notes

For tasks that span many turns — research, multi-file refactors, investigations — Claude writes intermediate findings and state to `.claude/project/task-notes.md` rather than relying on the context window alone. It acts as a scratchpad: key decisions, discovered constraints, and the current sub-goal. The file is cleared or archived at task completion.

This prevents context loss mid-task and avoids re-deriving information already established earlier in the session.

### Subagent Context Isolation

Subagents are used not only for parallelism but to contain sub-tasks whose intermediate state would otherwise pollute the main context. When a sub-task produces large intermediate output (raw search results, log analysis, code review) and only the synthesised conclusion is needed downstream, it is delegated to a subagent. Only the result surfaces in the main conversation.

### Context Cache Design

Prompt caches are per-model and invalidate when the system prompt changes. To preserve cache hits, dynamic content (session ID, memory, reminders) is injected via hook stdout into the message stream — not by editing the system prompt mid-session. `<system-reminder>` tags are used for message injections. Models are not switched mid-session, as caches do not transfer across models.

### Session Closure

When a task reaches a natural conclusion, Claude proactively offers a session wrap-up rather than waiting to be asked.
