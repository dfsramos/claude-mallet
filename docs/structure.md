# Project Structure

```
.
├── CLAUDE.md                          # Core directives (persona, rules, workflow)
├── README.md                          # Project overview and installation instructions
├── install.sh                         # Automated installer for deploying the framework to a project
├── .claude/
│   ├── settings.json                  # Hook registrations
│   ├── hooks/
│   │   └── session-start.sh           # Generates a unique session ID at startup
│   ├── skills/
│   │   ├── discover/
│   │   │   └── SKILL.md               # Structured project analysis and skill opportunity identification
│   │   └── reviewing-sessions/
│   │       └── SKILL.md               # Structured end-of-session retrospective
│   ├── sessions/
│   │   ├── .current                   # Active session ID (gitignored)
│   │   └── <session-id>.md            # Per-session wrap-up records (gitignored)
│   └── skill-backlog.md               # Ideas for future skills (created on demand)
├── source/
│   ├── CLAUDE.md                      # Template CLAUDE.md installed into target projects
│   └── .claude/                       # Template .claude/ directory installed into target projects
│       ├── settings.json
│       ├── hooks/
│       │   └── session-start.sh
│       ├── project/
│       │   └── memory.md
│       └── skills/
│           ├── discover/SKILL.md
│           └── reviewing-sessions/SKILL.md
└── docs/
    ├── structure.md                   # This file
    ├── directives.md                  # Behavioral rules defined in CLAUDE.md
    ├── hooks.md                       # Automatic actions triggered by Claude Code events
    └── skills.md                      # Reusable capabilities and the skill backlog
```

When the framework is installed into a project, the target project may also contain:

```
<target-project>/
├── CLAUDE.md                          # Installed from source/CLAUDE.md
└── .claude/
    ├── project/
    │   ├── CLAUDE.md                  # Project-specific conventions (optional, not from source)
    │   ├── memory.md                  # Project-specific long-term memory (optional, installed from source)
    │   └── skills/                    # Project-specific skills (optional, not from source)
    ├── hooks/
    ├── skills/
    └── sessions/
```

## Key Directories

| Path | Purpose |
|---|---|
| `.claude/hooks/` | Scripts triggered automatically by Claude Code events |
| `.claude/skills/` | Reusable skill definitions (each in its own subdirectory) |
| `.claude/sessions/` | Runtime session data (gitignored) |
| `source/` | Template files installed into target projects via `install.sh` |

## Key Files

| File | Purpose |
|---|---|
| `CLAUDE.md` | Root directives file — defines persona, rules, and workflow |
| `install.sh` | Interactive installer that copies `source/` into an existing project |
| `.claude/settings.json` | Registers hooks and other Claude Code settings |
| `.claude/skill-backlog.md` | Running log of skill ideas captured during sessions |
