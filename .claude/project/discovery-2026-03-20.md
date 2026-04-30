# Project Discovery Report
Date: 2026-03-20
Project: ai-framework

## Overview

A portable Claude Code configuration framework — no application code. The repo ships a `source/` directory (the install payload) and a live `.claude/` directory (the framework's own Claude setup). Core components: `CLAUDE.md` directives, a `session-start.sh` hook, seven skills (five distributed, two framework-only), and a knowledge-skill template. No external dependencies, no package manager, no build system.

---

## External Services Detected

| Service | Purpose | Integration Type | Notes |
|---------|---------|-----------------|-------|
| GitHub (via `gh` CLI) | Framework update checks | CLI (`gh api`) | Used in `session-start.sh` to compare installed hash vs HEAD |
| GitHub (via `git`) | Remote install / update | `git clone --depth=1` | Used in `install.md` and `update` skill |

No third-party SDKs. No auth providers. No data services. No monitoring.

---

## Recommended MCP Servers

None. The project has no third-party library dependencies and no fast-moving ecosystem components. Context7 is not warranted here.

---

## Issues Found

### Bug — Harvest skill references a deleted file

**File:** `.claude/project/skills/harvest/SKILL.md`, step 4 summary

The final summary block contains:

```
Reminder: re-run install.sh on the target to propagate
any newly promoted base skills:

  ./install.sh <TARGET>
```

`install.sh` was deleted when the `harvest-skill` feature was completed. The correct instruction is to use the `install` skill inside this repo, not a shell script. This will mislead anyone running harvest.

---

### Drift — `source/` settings.json has DB permissions that the live settings.json lacks

**Files compared:**
- `source/.claude/settings.json` — 47 lines, includes 31 read-only DB permission rules (mariadb, mysql, psql, sqlite3: SELECT, SHOW, DESCRIBE, EXPLAIN)
- `.claude/settings.json` — 15 lines, hooks only

The source settings (installed into target projects) allow read-only DB CLI access out of the box. The framework's own settings do not. This is likely intentional — the framework repo has no DB to query — but worth confirming. If the intent is to have the framework repo mirror what gets installed, they should match.

---

### Missing skill in source — `install` not distributed, `update` not local

By design:
- `.claude/skills/install/` is framework-only (not in `source/`) — correct, install is for framework authors
- `source/.claude/skills/update/` is target-only (not in live `.claude/skills/`) — correct, update requires `framework.json`

No action required, but this asymmetry is worth documenting so future skill authors know the distinction.

---

### Stale session files in `.claude/sessions/`

Three session files exist on disk using the old random-name format (`eager-peak-winds-6206.md`, `pure-deer-blooms-7034.md`, `true-dune-reads-6927.md`). These are gitignored but unused — the current system uses the Claude session ID directly (not random names). Can be deleted if desired.

---

### `reviewing-sessions` skill has no save step

The skill ends at step 4a (memory audit). No step saves the wrap-up output to `.claude/sessions/<session-id>.md`. The existing session files suggest this was once done, but the current skill omits it. Whether this is intentional (wrap-up is conversational-only) or an omission is unclear. The skill backlog item "Hooks Layer" notes that a session-end hook could automate this.

---

### Completed feature plans accumulate in `.claude/features/`

`.claude/features/harvest-skill/` is `Status: done` but remains on disk and in git. There is no cleanup convention for completed plans. Over time this directory will grow.

---

## Skill Backlog Items (unactioned)

Both items in `.claude/project/skill-backlog.md` are still open:

1. **Hooks Layer** — session-end hook for auto-persisting wrap-up state; git-push reminder hook. High value, needs a dedicated session.
2. **MCP Server Catalog for Discovery** — structured catalog of MCP servers the discover skill can consult, instead of hardcoding Context7 inline. Medium value.

---

## Recommended Skills

### High Priority

- **`simplify`** (already a global skill, but not in source) — Confirm whether this should be distributed to target projects. If yes, add to `source/.claude/skills/`. If no, document the distinction.

### Medium Priority

- **`cleanup-features`** — A skill to archive or delete completed feature plans from `.claude/features/`. Low complexity; prevents directory bloat over long-lived repos.
- **`session-save`** — Either a hook or a reviewing-sessions step to write wrap-up output to `.claude/sessions/<session-id>.md`. Would complete the session lifecycle.

### Low Priority (Future Consideration)

- **MCP server catalog** — Backlog item #2. Worth doing once there are 3+ MCP servers worth recommending.

---

## Project Conventions for `.claude/project/CLAUDE.md`

The framework repo does not currently have a `.claude/project/CLAUDE.md`. Conventions that would be worth capturing there:

- **Two-location rule**: every new skill in `.claude/skills/` must be mirrored to `source/.claude/skills/` (except framework-only skills like `install` and `harvest`).
- **Docs parity**: any change to a skill or hook must update the corresponding section in `docs/`.
- **Framework-only vs distributed**: `install` and `harvest` live only in the framework repo (never in `source/`); `update` lives only in `source/` (never in live `.claude/skills/`).

---

## Promotable to Framework

No project-specific skills to promote — `harvest` is already the framework's promotion mechanism.

---

## Next Steps

1. Fix the `install.sh` reference in `harvest/SKILL.md` — one-line change, high visibility bug.
2. Confirm whether `source/settings.json` DB permissions should be mirrored to `.claude/settings.json` or whether the divergence is intentional.
3. Create `.claude/project/CLAUDE.md` with the two-location rule and docs-parity convention.
4. Decide on `reviewing-sessions` save step — either add it or document that wrap-up is conversational-only.
5. Plan the Hooks Layer backlog item (session-end hook) as a feature in a future session.
6. Clean up old session files from `.claude/sessions/` (optional, cosmetic).
