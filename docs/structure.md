# Project Structure

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

## Key Directories

| Path | Purpose |
|---|---|
| `.claude/hooks/` | Scripts triggered automatically by Claude Code events |
| `.claude/skills/` | Reusable skill definitions (each in its own subdirectory) |
| `.claude/sessions/` | Runtime session data (gitignored) |

## Key Files

| File | Purpose |
|---|---|
| `CLAUDE.md` | Root directives file — defines persona, rules, and workflow |
| `.claude/settings.json` | Registers hooks and other Claude Code settings |
| `.claude/skill-backlog.md` | Running log of skill ideas captured during sessions |
