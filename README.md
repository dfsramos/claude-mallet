# ai-framework

A configuration framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that customizes agent behavior through directives, hooks, skills, and session tracking.

## What This Is

This project is a portable set of configuration files that sit inside a repository's `.claude/` directory (and a root `CLAUDE.md`). When Claude Code opens a project containing these files, it automatically adopts the defined persona, enforces the specified rules, and gains access to registered skills and hooks.

It is not application code. It is a meta-project: a reusable scaffold for shaping how Claude Code operates.

## Structure

```
.
├── CLAUDE.md                          # Core directives (persona, rules, workflow)
├── .claude/
│   ├── settings.json                  # Hook registrations
│   ├── hooks/
│   │   └── session-start.sh           # Generates a unique session ID at startup
│   ├── skills/
│   │   └── reviewing-sessions/
│   │       └── SKILL.md               # Structured end-of-session retrospective
│   ├── sessions/
│   │   ├── .current                   # Active session ID (gitignored)
│   │   └── <session-id>.md            # Per-session wrap-up records (gitignored)
│   └── skill-backlog.md               # Ideas for future skills (created on demand)
└── .gitignore
```

## Components

### Directives (`CLAUDE.md`)

The root `CLAUDE.md` defines behavioral rules that Claude Code follows for every interaction:

| Directive | Purpose |
|---|---|
| Evidence-Based Approach | Require proof with every conclusion; never speculate |
| Communication Style | Calm, concise, Markdown-formatted, no hype |
| Interaction Style | Proactive reads, run commands instead of suggesting them |
| Tool Preferences | Prefer dedicated tools over Bash for file operations |
| Destructive Operations | Never delete/overwrite without explicit confirmation |
| Production Awareness | Stop and confirm before acting on live environments |
| Git Workflow | Branch off `master`, open PRs, never commit directly |
| Session Closure | Proactively offer a wrap-up when a task concludes |

### Session ID Hook (`.claude/hooks/session-start.sh`)

Runs automatically when a Claude Code session starts. Generates a unique identifier in the format `adjective-noun-verb-timestamp` (e.g., `tall-pine-lifts-7488`) and:

- Exports it as the `SESSION_ID` environment variable
- Writes it to `.claude/sessions/.current`
- Injects it into Claude's context via stdout

### Session Wrap-Up Skill (`.claude/skills/reviewing-sessions/`)

A structured retrospective triggered by phrases like "wrap up" or "all done". It produces:

1. A session summary (goal, approach, outcome)
2. What went well
3. What went poorly (with specific references)
4. Applied improvements to skills or directives
5. A session record saved to `.claude/sessions/<session-id>.md`

### Skill Backlog (`.claude/skill-backlog.md`)

During any session, observations about potential new skills or improvements are silently appended here. The user reviews and promotes items at their own pace.

## Usage

Clone or copy this framework into a project directory. Claude Code will pick up the configuration automatically when the project is opened.

```bash
# Clone into a new project
git clone <repo-url> my-project

# Or copy the configuration files into an existing project
cp -r ai-framework/.claude /path/to/existing-project/
cp ai-framework/CLAUDE.md /path/to/existing-project/
```

Customize `CLAUDE.md` and the skills to match your workflow.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Bash (for the session-start hook)
