# Project Structure

```
.
├── CLAUDE.md                          # Core directives (persona, rules, workflow)
├── README.md                          # Project overview and installation instructions
├── install.md                         # Remote installation instructions (used by install flow)
├── .claude/
│   ├── settings.json                  # Hook registrations
│   ├── statusline.sh                  # Statusline renderer
│   ├── hooks/
│   │   ├── session-start.sh           # Session startup actions
│   │   └── user-prompt-submit.sh      # Complexity scoring and turn tracking
│   ├── skills/
│   │   ├── create-pr/SKILL.md
│   │   ├── discover/SKILL.md
│   │   ├── plan-feature/SKILL.md
│   │   ├── reviewing-sessions/SKILL.md
│   │   ├── systematic-debugging/SKILL.md
│   │   ├── task-calibrate/SKILL.md
│   │   └── update/SKILL.md
│   ├── templates/
│   │   └── knowledge-skill/SKILL.md   # Template for domain knowledge skills
│   ├── features/
│   │   └── <slug>/                    # Feature plans committed directly to master
│   │       ├── plan.md
│   │       └── tasks/
│   └── project/                       # Framework-repo-specific content (NOT installed into target projects)
│       ├── CLAUDE.md                  # Project conventions
│       ├── lessons.md                 # Recorded after user corrections
│       ├── skill-backlog.md           # Ideas for future skills
│       └── skills/
│           └── harvest/SKILL.md       # Maintenance skills for this repo
└── docs/
    ├── structure.md                   # This file
    ├── directives.md                  # Behavioral rules defined in CLAUDE.md
    ├── hooks.md                       # Automatic actions triggered by Claude Code events
    └── skills.md                      # Reusable capabilities and the skill backlog
```

When the framework is installed into a project, the target gains:

```
<target-project>/
├── CLAUDE.md                          # Installed (overwrites any existing)
└── .claude/
    ├── settings.json                  # Installed (overwrites)
    ├── statusline.sh                  # Installed (overwrites)
    ├── hooks/                         # Installed (overwrites)
    ├── skills/                        # Installed (overwrites)
    ├── templates/                     # Installed (overwrites)
    ├── framework.json                 # Install metadata (gitignored, written once per install/update)
    ├── settings.local.json            # User permissions (gitignored, never touched by install/update)
    └── project/                       # Project-specific content (never touched by install/update)
        ├── CLAUDE.md                  # Project conventions (optional)
        ├── memory.md                  # Project memory (optional, created on demand)
        ├── overrides/                 # Per-skill amendments to base skills (optional)
        │   └── <skill-name>.md        # Amendments for the named base skill
        └── skills/                    # Project-specific skills (optional)
```

## Key Directories

| Path | Purpose |
|---|---|
| `.claude/hooks/` | Scripts triggered automatically by Claude Code events |
| `.claude/skills/` | Framework skill definitions — installed into target projects |
| `.claude/templates/` | Skill templates — installed into target projects |
| `.claude/features/` | Feature plans committed directly to master; visible across all branches (NOT installed) |
| `.claude/project/` | Framework-repo-specific content (NOT installed into target projects) |

## Key Files

| File | Purpose |
|---|---|
| `CLAUDE.md` | Root directives file — defines persona, rules, and workflow |
| `install.md` | Remote-install instructions followed by Claude on first install |
| `.claude/settings.json` | Registers hooks and other Claude Code settings |
| `.claude/project/CLAUDE.md` | Project-specific conventions layered on top of the root `CLAUDE.md` |
| `.claude/project/memory.md` | Persistent project-specific knowledge, injected at session start |
| `.claude/project/skill-backlog.md` | Running log of skill ideas captured during sessions |
