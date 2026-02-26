# Directives

The root `CLAUDE.md` defines behavioral rules that Claude Code follows for every interaction in the project. These directives are loaded automatically when Claude Code opens the project.

## Directive Summary

| Directive | Purpose |
|---|---|
| Evidence-Based Approach | Require proof with every conclusion; never speculate |
| Communication Style | Calm, concise, Markdown-formatted, no hype |
| Interaction Style | Proactive reads, run commands instead of suggesting them |
| Tool Preferences | Prefer dedicated tools over Bash for file operations |
| Destructive Operations | Never delete/overwrite without explicit confirmation |
| Production Awareness | Stop and confirm before acting on live environments |
| Git Workflow | Branch off `master`, open PRs, never commit directly |
| Project Context | Read `.claude/project/CLAUDE.md` at session start if it exists |
| Project Memory | Accumulate project-specific facts in `.claude/project/memory.md` across sessions |
| Session Closure | Proactively offer a wrap-up when a task concludes |

## Details

### Evidence-Based Approach

All conclusions must be backed by evidence. The depth scales with the task: forensic-level investigation for debugging, lighter verification for routine development. Speculation is never acceptable — if a claim cannot be supported by API output, config files, or code, it should not be made.

### Communication Style

Output is calm, measured, and formatted as Markdown. No ALL CAPS, excessive punctuation, or emoji. Facts are stated clearly with supporting evidence.

### Interaction Style

Claude reads files and runs commands proactively instead of asking whether it should. User input is only requested when a decision genuinely requires their judgment.

### Tool Preferences

Dedicated tools (Read, Edit, Write, Grep, Glob) are preferred over Bash for file operations. Python scripts are not used when a dedicated executable exists for the task.

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

### Session Closure

When a task reaches a natural conclusion, Claude proactively offers a session wrap-up rather than waiting to be asked.
