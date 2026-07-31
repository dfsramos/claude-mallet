# Task: docs
Status: pending
Deps: 01, 02, 03, 04, 05, 06, 07, 08

## Goal
Bring `docs/` and `README.md` in line with the user-level install and the `.mallet/` layout.

## Context
This repo's `.claude/project/CLAUDE.md` requires docs parity: skill changes update `docs/skills.md`, hook changes `docs/hooks.md`, structural changes `docs/structure.md`, directive changes `docs/directives.md`. This feature touches all four plus `README.md`. Reference counts from the audit: `docs/skills.md` 20, `docs/directives.md` 13, `docs/hooks.md` 5, `docs/structure.md` 3, `README.md` 2.

## Steps

1. **`docs/structure.md`** — rewrite both trees. The source-repo tree gains `.claude/settings.fragment.json`, `.claude/merge-settings.sh`, `.claude/skills/migrate/`, and shows this repo's own state under `.mallet/`. Replace the "When the framework is installed into a project" tree with two trees: what lands in `~/.claude/`, and what a target repo looks like afterwards:
   ```
   <repo>/
   ├── CLAUDE.md                  project's own only, or absent
   ├── .claude/
   │   ├── settings.json          opt-in hook registrations only, or absent
   │   └── settings.local.json    permissions (never touched)
   └── .mallet/
       ├── .gitignore             ships with install
       ├── conventions.md         project conventions
       ├── memory.md  lessons.md  skill-backlog.md
       ├── missions/  overrides/  skills/  discovery-*.md
       └── features/  pipeline-state/
   ```
   Update both key-paths tables: `~/.claude/*` for payload, `.mallet/*` for state, and note that `.claude/` retains only the two harness-pinned settings files. Update lines 94, 95, and 104.

2. **`docs/directives.md`** — rewrite lines 21–25, 78, 84, 86, 90, 92, 96, 102, 106, 124 per the `plan.md` mapping. Rename the "Project Context" entry to point at `.mallet/conventions.md`. Add a short section stating that directives now load from `~/.claude/CLAUDE.md` in every session, that a repo's own `CLAUDE.md` stacks on top rather than being overwritten, and that `.mallet/conventions.md` is the per-project escape hatch.

3. **`docs/hooks.md`** — update lines 14, 15, 82, 89, 171 for `.mallet/`. Document that hook scripts live at `~/.claude/hooks/` while their data resolves through `$CLAUDE_PROJECT_DIR`. Add the new legacy-detection behaviour and its `.mallet/.migration-declined` suppression file (task 07 step 4). Record the update-check 24-hour cache at `~/.claude/.mallet-update-check` and the statusline no longer blanking when `framework.json` is absent (task 04). State that base hooks register globally while the three opt-in hooks register per repo.

4. **`docs/skills.md`** — update all 20 references. Rewrite the install and update sections (lines 17, 22, 61) for the merge-not-overwrite and per-entry-replacement behaviour, and mention the manifest. Add a `migrate` entry covering its six phases, its two entry points, and its untracked-only deletion rule. Update the harvest entry (lines 207, 213, 214) and the project-file entries (lines 223, 227, 235, 241, 247, 249, 251) to `.mallet/` paths.

5. **`README.md`** — rewrite the installation section for the user-level target and one-command legacy cleanup. Update lines 32 and 54. Add a short "Migrating from a per-project install" section aimed at someone who already has Mallet in their repos: what moves, what is preserved, what is only reported, and where the backups land. State plainly that a repo's own `CLAUDE.md` is no longer overwritten.

6. Re-run the task 03 regression greps across `docs/` and `README.md` and confirm zero stale references.

## TDD Checklist
_(Documentation only — no runtime behaviour. Verification is by assertion, not test.)_
- [ ] `grep -rn '\.claude/\(project\|features\|pipeline-state\)' docs/ README.md` returns zero matches
- [ ] `grep -rn 'settings\.json' docs/` describes merging, never overwriting
- [ ] Every path in the `docs/structure.md` trees exists in the repo or is explicitly marked created-on-demand
- [ ] Every skill in `.claude/skills/` has a `docs/skills.md` entry, and every entry names a skill that exists
- [ ] Every hook in `.claude/hooks/` has a `docs/hooks.md` entry, with default-versus-opt-in stated correctly
- [ ] `README.md` install instructions, followed literally against a scratch `HOME`, produce a working install

## Notes
Item 6 is the cheapest guard against the mapping table being applied inconsistently across 110 sites.
