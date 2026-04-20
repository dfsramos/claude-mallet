# Project Structure

```
.
├── CLAUDE.md                          # Core directives (persona, rules, workflow)
├── README.md                          # Project overview and installation instructions
├── .claude/
│   ├── settings.json                  # Hook registrations
│   ├── features/
│   │   └── <slug>/                    # Feature plans committed directly to master
│   │       ├── plan.md
│   │       └── tasks/
│   ├── hooks/
│   │   └── session-start.sh           # Generates a unique session ID at startup
│   ├── project/
│   │   ├── lessons.md                 # Lessons recorded after user corrections
│   │   └── skills/
│   │       └── harvest/
│   │           └── SKILL.md           # Drift detection and skill promotion for installed projects
│   ├── skills/
│   │   ├── discover/
│   │   │   └── SKILL.md               # Structured project analysis and skill opportunity identification
│   │   ├── install/
│   │   │   └── SKILL.md               # Install the framework into a target project
│   │   ├── plan-feature/
│   │   │   └── SKILL.md               # Intake-to-execution feature planning pipeline
│   │   ├── systematic-debugging/
│   │   │   └── SKILL.md               # Four-phase root-cause-first debugging methodology
│   │   └── reviewing-sessions/
│   │       └── SKILL.md               # Structured end-of-session retrospective
│   ├── templates/
│   │   └── knowledge-skill/
│   │       └── SKILL.md               # Template for domain knowledge skills
│   └── project/
│       └── skill-backlog.md           # Ideas for future skills (created on demand)
├── source/
│   ├── CLAUDE.md                      # Template CLAUDE.md installed into target projects
│   └── .claude/                       # Template .claude/ directory installed into target projects
│       ├── settings.json
│       ├── hooks/
│       │   └── session-start.sh
│       ├── skills/
│       │   ├── discover/SKILL.md
│       │   ├── plan-feature/SKILL.md
│       │   ├── systematic-debugging/SKILL.md
│       │   └── reviewing-sessions/SKILL.md
│       └── templates/
│           └── knowledge-skill/SKILL.md
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
    │   ├── CLAUDE.md                  # Project-specific conventions (optional)
    │   ├── memory.md                  # Project-specific long-term memory (optional, created on demand)
    │   └── skills/                    # Project-specific skills (optional)
    ├── hooks/
    ├── skills/
    └── sessions/
```

## Key Directories

| Path | Purpose |
|---|---|
| `.claude/hooks/` | Scripts triggered automatically by Claude Code events |
| `.claude/features/` | Feature plans committed directly to master; visible across all branches |
| `.claude/skills/` | Reusable skill definitions (each in its own subdirectory) |
| `.claude/project/skills/` | Framework-specific skills not installed into target projects |
| `.claude/sessions/` | Runtime session data (gitignored) |
| `source/` | Template files installed into target projects via the `install` skill |

## Key Files

| File | Purpose |
|---|---|
| `CLAUDE.md` | Root directives file — defines persona, rules, and workflow |
| `.claude/skills/install/SKILL.md` | Installs the framework into an existing project |
| `.claude/settings.json` | Registers hooks and other Claude Code settings |
| `.claude/project/skill-backlog.md` | Running log of skill ideas captured during sessions |
| `.claude/project/memory.md` | Persistent project-specific knowledge store, injected at session start |
