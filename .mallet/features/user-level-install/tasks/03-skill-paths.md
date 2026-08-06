# Task: skill-paths
Status: done
Deps: —

## Goal
Rewrite every path reference in `CLAUDE.md`, the skills, and the agents so state resolves to `.mallet/` and framework payload resolves to `~/.claude/`.

## Context
110 references to `.claude/project|features|pipeline-state` exist across 20 files. A second category — references to the framework payload itself (`.claude/skills/`, `.claude/agents/`, `.claude/templates/`, `.claude/hooks/`, `.claude/framework.json`) — must gain a `~/` prefix now that the payload is user-level.

`install.md` (task 06), `.claude/skills/update/SKILL.md` (task 08), and `docs/` plus `README.md` (task 09) are rewritten wholesale by their own tasks and are **out of scope here**. Historical snapshots are left untouched as dated records: `.claude/project/discovery-2026-03-20.md`, `.claude/project/discovery-2026-06-04.md`, and everything under `.claude/features/harvest-skill/`.

## Steps

### A. State paths → `.mallet/`

Apply the mapping table in `plan.md`. Verified reference sites:

| File | Lines |
|---|---|
| `CLAUDE.md` | 78, 88, 92, 94, 132, 136, 147, 188, 189, 193, 195 |
| `.claude/skills/adr/SKILL.md` | 89 |
| `.claude/skills/checkpoint/SKILL.md` | 13, 27, 40 |
| `.claude/skills/discover/SKILL.md` | 127, 136, 179, 196, 198 |
| `.claude/skills/hooks-setup/SKILL.md` | 46 |
| `.claude/skills/implement-feature/SKILL.md` | 18, 43, 67, 204 |
| `.claude/skills/plan-feature/SKILL.md` | 9, 27, 67, 77, 96, 140 |
| `.claude/skills/reviewing-sessions/SKILL.md` | 60, 70, 84, 87, 121 |
| `.claude/project/CLAUDE.md` | 5, 11 |
| `.claude/project/lessons.md` | 12, 13 |
| `.claude/project/skills/harvest/SKILL.md` | 47, 58, 69, 76, 93 |

Edit `.claude/project/**` content **in place at its current path**. Task 10 performs the file move; keeping content and move in separate tasks avoids doing both at once.

Three sites need more than a path swap:

- `CLAUDE.md:189` — "If `.claude/project/skills/` exists, treat it as an additional skills directory alongside `.claude/skills/`" becomes `.mallet/skills/` alongside `~/.claude/skills/`. Both halves change.
- `CLAUDE.md:188` — "If `.claude/project/CLAUDE.md` exists" becomes `.mallet/conventions.md`. Reword so it no longer reads as a CLAUDE.md file: "If `.mallet/conventions.md` exists, read it at session start."
- `.claude/skills/plan-feature/SKILL.md:9,27,77,96,140` — the `/tmp/feature-planning` worktree paths become `/tmp/feature-planning/.mallet/features/`.

### B. Framework payload paths → `~/.claude/`

1. Enumerate the sites:
   ```bash
   grep -rn '\.claude/\(skills\|agents\|templates\|hooks\|statusline\.sh\|framework\.json\|settings\.fragment\.json\)' \
     --include='*.md' CLAUDE.md .claude/skills/ .claude/agents/ .claude/templates/ \
     | grep -v '^\.claude/skills/update/' | grep -v '~/\.claude'
   ```

2. Apply these rules to each hit:

| Reference kind | Rewrite to |
|---|---|
| Framework skill definitions | `~/.claude/skills/` |
| Agent definitions | `~/.claude/agents/` |
| Templates (e.g. `knowledge-skill`) | `~/.claude/templates/` |
| Hook **scripts** | `~/.claude/hooks/` |
| `statusline.sh` | `~/.claude/statusline.sh` |
| `framework.json` | `~/.claude/framework.json` |
| Hook **registrations** for the 3 opt-in hooks | `.claude/settings.json` — unchanged, stays per repo |
| `.claude/settings.local.json` | unchanged |

3. `.claude/skills/hooks-setup/SKILL.md` needs both halves corrected: line 56's existence check becomes `~/.claude/hooks/<name>.sh`, and line 68's registration command becomes `bash "$HOME/.claude/hooks/<name>.sh"` while the file it writes to stays the project's `.claude/settings.json`. Lines 13 and 57 continue to read the project `.claude/settings.json`.

4. `.claude/skills/plan-feature/SKILL.md:67` — the template copy source becomes `~/.claude/templates/knowledge-skill/SKILL.md`; the destination becomes `.mallet/skills/<domain>-knowledge/SKILL.md`.

## TDD Checklist
- [x] Write failing assertion: `grep -rn '\.claude/\(project\|features\|pipeline-state\)' CLAUDE.md .claude/skills/ .claude/agents/ .claude/templates/ .claude/project/` returns matches
- [x] Confirm it fails (red)
- [x] Apply sections A and B
- [x] Confirm the assertion now returns zero matches, excluding the historical files named in Context
- [x] Assert no `$CLAUDE_PROJECT_DIR/.claude/hooks` or `$CLAUDE_PROJECT_DIR/.claude/skills` references remain: `grep -rn 'CLAUDE_PROJECT_DIR/\.claude/\(hooks\|skills\|agents\|templates\)' .` returns nothing
- [x] Assert the three opt-in hook registrations still target the *project* `.claude/settings.json`, not `~/.claude/settings.json`
- [x] Read `CLAUDE.md` start to finish and confirm no sentence now contradicts itself (e.g. a directive telling Claude to read a file that moved)

## Notes
Section B's enumeration is deliberately a command rather than a line list — the payload-path references were not individually audited, unlike section A's.
