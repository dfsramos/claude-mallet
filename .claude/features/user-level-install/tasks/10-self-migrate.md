# Task: self-migrate
Status: pending
Deps: 09

## Goal
Migrate this repo's own state to `.mallet/`, install Mallet at `~/.claude/`, then run the migration across the eight real installs as live validation.

## Context
The final task and the only one that touches repos outside this one. The user explicitly asked for the existing per-project installs to be cleaned up, which authorises writes outside this project under the base Scope of Changes directive — but every repo still gets its own confirmation, and tracked files are still report-only.

Fixtures proved the mechanism in task 05. This proves it against the real variants: a stale April install, a pure-Mallet tracked `CLAUDE.md`, a project-authored `CLAUDE.md` needing a surgical strip, and a schema-broken `framework.json`.

## Steps

### A. Migrate this repo

1. `mkdir -p .mallet`
2. `git mv .claude/project/CLAUDE.md .mallet/conventions.md`
3. `git mv` each of `.claude/project/lessons.md`, `.claude/project/skill-backlog.md`, `.claude/project/discovery-2026-03-20.md`, `.claude/project/discovery-2026-06-04.md` into `.mallet/`
4. `git mv .claude/project/skills .mallet/skills` and `git mv .claude/project/missions .mallet/missions`
5. `git mv .claude/features .mallet/features`
6. `rmdir .claude/project` — confirm it is empty first; if not, move the remainder and report each file by name
7. Write `.mallet/.gitignore` with `pipeline-state/`, `compact-snapshot.md`, `discovery-*.md`, `missions/`
   - The two existing `discovery-*.md` files are already tracked. Keep them tracked: add `!discovery-2026-03-20.md` and `!discovery-2026-06-04.md` negations, or `git add -f`. Do not let this task silently untrack committed history.
8. `git rm .claude/framework.json` — the version now lives at `~/.claude/framework.json`
9. Read `.gitignore` and update any `.claude/pipeline-state/` or `.claude/framework.json` entry to its `.mallet/` equivalent
10. Confirm what remains in this repo's `.claude/`: `agents/`, `hooks/`, `skills/`, `templates/`, `statusline.sh`, `settings.fragment.json`, `merge-settings.sh`, `settings.local.json`. These are payload source of truth and this repo's permissions — they stay.
11. Note in `state.md` that this repo no longer carries live per-project hook registrations; its behaviour now comes from `~/.claude/`, same as any other project.

### B. Install at user level

12. Follow the rewritten `install.md` against the real `$HOME`, pointing at this working tree rather than a GitHub tarball so unreleased changes are what gets tested.
13. Verify `~/.claude/skills/backburner/` survived — it is user-authored and not in the manifest.
14. Verify `~/.claude/settings.json` retains `model: opus`, `effortLevel: xhigh`, `enabledPlugins`, and the `Stop`/`Notification` notify hooks, and gained the 4 base hooks plus `statusLine`.
15. Start a fresh session in an unrelated directory and confirm: directives load, the statusline renders all three lines, and no error output appears.

### C. Verify the candidate list

16. Run the `migrate` skill's discovery phase and reconcile its output against the known set:

    | Repo | Recorded | Notes |
    |---|---|---|
    | `Cludo/cludo-lambdas` | `2c37851` | untracked; `.git/info/exclude` present |
    | `Cludo/Cludo.PuppeteerService` | `2c37851` | untracked; exclude present |
    | `Cludo/Cludo.App.Backend` | `2c37851` | untracked; exclude present; also check the nested `Source/.claude` |
    | `Cludo/ai` | `2c37851`, pre-rename repo name | **tracked `CLAUDE.md`, pure Mallet payload** — report only |
    | `Cludo/gitops` | `2c37851` | untracked, no exclude — shows `?? .claude/` today |
    | `Cludo/Cludo.WebRenderService` | `275d864` | stale April install, pre-rename repo name |
    | `Personal/exocortex` | `{"commit": "2ae59d1"}` | **broken schema; tracked `CLAUDE.md` with `## Vault Context`** |

17. Investigate the two unexplained `.claude` directories found during assessment — `/mnt/c/Repositories/Cludo/Cludo.App.Backend/Source/.claude` and `/home/dfsramos/repos/Cludo/.claude`. Classify each as legacy install, unrelated, or already migrated before touching it.

### D. Migrate, one repo at a time

18. Start with `Cludo/gitops` — untracked, no exclude, current version, nothing tracked to complicate it. Verify the end state fully before continuing.
19. Then `Cludo/Cludo.WebRenderService` to exercise the stale-SHA path, where the historical payload differs from HEAD.
20. Then `Personal/exocortex` to exercise the broken schema and the surgical strip. Assert the resulting `CLAUDE.md` contains exactly `## Vault Context` and its body, and that the Obsidian conventions it documents are intact.
21. Then `Cludo/ai` to exercise report-only on a tracked pure-payload `CLAUDE.md`. Assert nothing was written and the `git rm` command was reported.
22. Then the three remaining Cludo repos.
23. After each: `git status` shows no unexpected changes, `.claude/settings.local.json` is byte-identical, and `.mallet/` holds everything that was under `.claude/project/`.

### E. Close out

24. For each repo whose `.mallet/` should stay untracked, replace the `.claude/`+`CLAUDE.md` lines in `.git/info/exclude` with a single `.mallet/` line. Ask per repo — some may now want `.mallet/` committed.
25. Set `plan.md` `Status: done`, record outcomes in `state.md`, and commit directly to master per this repo's git-workflow override.
26. Spawn a subagent to independently verify the work per the base Verification Before Done directive: confirm no repo lost project state, no tracked file was modified without confirmation, and `~/.claude/` is internally consistent with its manifest.

## TDD Checklist
- [ ] Before section A, capture `find . -path ./.git -prune -o -type f -print | sort > <scratchpad>/before.txt`; after, assert every former `.claude/project/**` and `.claude/features/**` file has a `.mallet/**` counterpart and none vanished
- [ ] After section A, `grep -rn '\.claude/\(project\|features\)' .` returns only the historical discovery reports and `harvest-skill` plan files
- [ ] After section B, run every hook manually against this repo and assert each exits 0 with expected output
- [ ] After each repo in section D, assert `git status --porcelain` in that repo shows nothing unexpected and `.claude/settings.local.json` is unchanged
- [ ] After section D, assert `~/.claude/mallet-migration-backup-*.tar.gz` exists for every migrated repo and each extracts cleanly
- [ ] Final: re-run the assessment inventory — `find /mnt/c/Repositories /home/dfsramos/repos -maxdepth 4 -name framework.json -path '*/.claude/*'` returns zero results
- [ ] Final: `~/.claude/framework.json` is the only `framework.json`, and its manifest matches the payload on disk

## Notes
Sections C and D are destructive across repos the user works in daily. Confirm per repo; do not batch. If any step surprises, stop and report rather than continuing down the list — the backups exist but a half-migrated repo is worse than an unmigrated one.
