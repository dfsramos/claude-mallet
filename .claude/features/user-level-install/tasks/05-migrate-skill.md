# Task: migrate-skill
Status: pending
Deps: 01

## Goal
Author `.claude/skills/migrate/SKILL.md` — the engine that finds legacy per-project Mallet installs, backs them up, relocates their state to `.mallet/`, strips Mallet content from their `CLAUDE.md`, and prunes their `settings.json`.

## Context
Called by `install.md` (task 06) during a fresh user-level install, and offered by `session-start.sh` (task 07) when a legacy payload is detected in the current repo. Must work for other people's machines, not just this one — so it cannot assume a local clone of the framework repo, and it must tolerate the schema variants already in the wild.

Discovery uses session transcripts rather than directory-name decoding. `~/.claude/projects/` names are ambiguous: `/mnt/c/Repositories/Cludo/cludo-lambdas` encodes to `-mnt-c-Repositories-Cludo-cludo-lambdas`, where `-` is both a path separator and a literal character. The `.jsonl` transcripts inside each directory record an exact `cwd` field — verified to return `/mnt/c/Repositories/Cludo/cludo-lambdas` directly — so the encoded name is never parsed.

## Steps

Write `.claude/skills/migrate/SKILL.md` with the frontmatter description stating trigger conditions only (per the Skill Authoring directive), e.g.: *"Invoke when the user runs /migrate, says 'clean up the old Mallet installs', 'migrate to user-level Mallet', or when a session-start notice reports a legacy per-project payload in the current repo. Also invoked by the user-level install flow."*

Body phases:

### Phase 1 — Discover candidate repos

1. For each directory under `~/.claude/projects/`, extract every distinct `cwd`:
   ```bash
   find ~/.claude/projects -maxdepth 2 -name '*.jsonl' -print0 \
     | xargs -0 -r jq -r 'select(.cwd) | .cwd' 2>/dev/null | sort -u
   ```
2. Resolve each to its repository root with `git -C "<cwd>" rev-parse --show-toplevel`, discarding paths that are not in a git repo and paths that no longer exist. Deduplicate — transcripts record subdirectories and worktrees as separate `cwd` values.
3. Ask the user for any additional roots to scan, then run a bounded fallback for repos never used with Claude:
   ```bash
   find <root> -maxdepth 4 -type d -name .claude -not -path '*/node_modules/*'
   ```
4. Union both lists.

### Phase 2 — Detect legacy installs

For each candidate, classify by **file presence, not schema**:

- **Legacy install** — `.claude/framework.json` exists, OR both `.claude/skills/update/SKILL.md` and `.claude/agents/_contract.md` exist.
- Record the SHA by reading `.version` and falling back to `.commit`. Both variants are in the wild: exocortex's file is `{"commit": "2ae59d1...", "installed_at": "..."}` with no `repo` or `version` key. Record `unknown` if neither key resolves.
- Record `repo`, defaulting to the framework repo the install flow was given when the key is absent. Two installs still record the pre-rename `dfsramos/ai-framework`; GitHub redirects renamed repos, so the recorded value is usable as-is.
- Skip and report anything that has `.mallet/` but no legacy payload — already migrated.

### Phase 3 — Back up

Before any deletion, for each legacy repo:
```bash
tar -czf "$HOME/.claude/mallet-migration-backup-<YYYYMMDD>-<repo-basename>.tar.gz" \
  -C "<repo>" .claude CLAUDE.md 2>/dev/null
```
Report the backup path. If `tar` fails for a repo, skip that repo entirely and report it — never proceed to deletion without a backup.

### Phase 4 — Present and confirm

Print a table: repo path, recorded SHA, recorded repo name, whether `CLAUDE.md` is tracked, whether project state exists, backup path. State plainly what will be deleted and what will only be reported. Wait for explicit confirmation before Phase 5 — this is a destructive operation under the base CLAUDE.md rules, and contextual consent does not count.

### Phase 5 — Per-repo migration

In this order:

1. **Relocate state.** `mkdir -p <repo>/.mallet`, then `git mv` where tracked and `mv` otherwise, per the `plan.md` mapping table:
   - `.claude/project/CLAUDE.md` → `.mallet/conventions.md`
   - `.claude/project/{memory,lessons,skill-backlog,task-notes,compact-snapshot}.md` → `.mallet/`
   - `.claude/project/discovery-*.md` → `.mallet/`
   - `.claude/project/{missions,overrides,skills}/` → `.mallet/`
   - `.claude/features/` → `.mallet/features/`
   - `.claude/pipeline-state/` → `.mallet/pipeline-state/`
   - Anything else under `.claude/project/` → `.mallet/`, reported by name; never discarded
   - `rmdir .claude/project` only once empty
2. **Write `.mallet/.gitignore`:**
   ```gitignore
   pipeline-state/
   compact-snapshot.md
   discovery-*.md
   missions/
   ```
3. **Delete the framework payload — untracked only.** For each of `.claude/agents/`, `.claude/hooks/`, `.claude/skills/`, `.claude/templates/`, `.claude/statusline.sh`, `.claude/framework.json`: check `git ls-files --error-unmatch <path>`; delete when untracked, and when tracked leave it and add to the report with the exact `git rm -r --cached <path>` command.
4. **Prune `.claude/settings.json`:**
   - Remove hook entries whose command references `session-start.sh`, `user-prompt-submit.sh`, `pre-compact.sh`, `write-guard.sh`, or `statusline.sh` — these are global now.
   - Rewrite surviving entries for `typecheck.sh`, `push-confirm.sh`, `explore-redirect.sh` from `$CLAUDE_PROJECT_DIR/.claude/hooks/` to `$HOME/.claude/hooks/`. These are per-repo *choices* and must be preserved.
   - Remove Mallet's `statusLine` if it points at `.claude/statusline.sh`.
   - Drop event keys left with no hooks. Delete the file only if it reduces to `{}`; otherwise write back the pruned object.
   - Never touch `.claude/settings.local.json`.
5. **Strip `CLAUDE.md`:**
   - Fetch the exact historical payload: `curl -sfL "https://raw.githubusercontent.com/<repo>/<sha>/CLAUDE.md"`.
   - `diff` it against the repo's `CLAUDE.md`. Lines present only in the repo's copy are project-authored and must survive; a clean match means the file is pure Mallet payload.
   - If the delta is empty: delete the file when untracked; when tracked, report with `git rm CLAUDE.md`.
   - If the delta is non-empty: write the delta only, preserving its original heading order, and show the user the resulting diff. When the file is tracked, **write only on explicit per-repo confirmation**.
   - Fallback when the fetch fails or the SHA is `unknown`: strip whole `##` sections matching the known Mallet heading set, keep unknown sections, and require confirmation on the diff before writing.
   - After stripping, rewrite any `.claude/project/` references inside the surviving content per the mapping table, and report them.

### Phase 6 — Summary

Per repo: what was moved, deleted, pruned, stripped, and skipped; the backup path; and any `git` commands the user must run themselves. End with the count of repos migrated versus skipped.

## TDD Checklist
- [ ] Build a fixture tree under `<scratchpad>/migrate-fixtures/` with five repos: (a) untracked payload plus project state, (b) tracked `CLAUDE.md` that is pure Mallet payload, (c) tracked `CLAUDE.md` with extra project sections, (d) broken `framework.json` using the `commit` key, (e) already-migrated repo with `.mallet/` and no payload
- [ ] Write failing assertions for each fixture's expected end state
- [ ] Confirm they fail (red)
- [ ] Implement the skill and run it against the fixtures
- [ ] Assert (a) is fully cleaned with all project state present under `.mallet/` and nothing lost
- [ ] Assert (b) leaves the tracked file on disk, unmodified, and reports the `git rm` command
- [ ] Assert (c) yields a `CLAUDE.md` containing exactly the project-authored sections
- [ ] Assert (d) is detected and migrated despite the schema variant
- [ ] Assert (e) is skipped, not re-migrated
- [ ] Idempotency: run twice over all fixtures, assert the second run reports every repo as already migrated and changes nothing
- [ ] Assert a `tar` failure aborts that repo before any deletion
- [ ] Assert `.claude/settings.local.json` is byte-identical in every fixture afterwards
- [ ] Assert an opt-in hook registration survives with a rewritten `$HOME` path

## Notes
Fixture (c) mirrors exocortex, whose real delta is a 16-line `## Vault Context` section — the concrete case proving the strip works. Fixture (b) mirrors Cludo/ai, whose 29 headings match the payload exactly with no project content.
