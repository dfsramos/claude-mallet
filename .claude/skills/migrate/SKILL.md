---
name: migrate
description: Invoke when the user runs /migrate, says "clean up the old Mallet installs", "migrate to user-level Mallet", "remove the per-project Mallet", or when a session-start notice reports a legacy per-project payload in the current repo. Also invoked by the user-level install flow after a fresh install.
---

# Migrate Off Per-Project Mallet

Mallet installs once at `~/.claude/`. This skill removes the per-project payload that older installs left inside each repo, relocates that repo's Mallet state to `.mallet/`, and leaves everything else alone.

The deterministic mechanics live in two scripts next to this file. Do not reimplement them inline:

| Script | Job |
|---|---|
| `~/.claude/skills/migrate/detect.sh` | find legacy installs, emit TSV |
| `~/.claude/skills/migrate/migrate-repo.sh` | migrate one repo (dry-run unless `--yes`) |

## Non-negotiables

These are enforced by the scripts. Do not work around them:

- **Tracked files are never modified.** A git-tracked `CLAUDE.md` is left exactly as committed — no strip, no diff, no suggested command. Same for a tracked `settings.json` or payload directory: reported, not touched.
- **No ignore file is ever written by default.** Whether `.mallet/` is tracked is the user's decision. Mallet never edits a repo's `.gitignore`, and only touches `.git/info/exclude` or the global excludes file on an explicit answer in step 4.
- **`.claude/settings.local.json` is never touched.**
- **No backup, no deletion.** A repo whose backup fails is skipped whole.

---

## 1. Discover

```bash
bash ~/.claude/skills/migrate/detect.sh
```

With no arguments, candidates come from the `cwd` recorded in session transcripts under `~/.claude/projects/` — an accurate record of every repo Claude has actually run in. Ask whether to also scan additional roots, and if so:

```bash
bash ~/.claude/skills/migrate/detect.sh --roots <dir> [<dir> ...]
```

Output is TSV: `repo`, `sha`, `recorded-repo`, `claude-md-state`.

If the current repo is the only target (the session-start notice case), skip straight to step 3 for it alone.

---

## 2. Present

Render the rows as a table. State plainly, before asking for anything:

- what will be **moved** — `.claude/project/`, `.claude/features/`, `.claude/pipeline-state/` into `.mallet/`
- what will be **deleted** — the untracked framework payload only
- what will be **skipped** — every tracked file, named individually
- where backups land — `~/.claude/mallet-migration-backup-<timestamp>-<repo>.tar.gz`

Call out rows whose `claude-md-state` is `tracked`: those `CLAUDE.md` files stay as they are, and the user may want to deal with them separately later.

---

## 3. Confirm

Wait for explicit confirmation. This is a destructive operation under the base CLAUDE.md rules — contextual consent does not count, and confirmation for one repo is not confirmation for the rest. For more than three repos, confirm the list once, then report per repo as you go.

---

## 4. Ask the VCS question, once

Ask how `.mallet/` should be treated, and apply only what the user picks:

| Answer | Action |
|---|---|
| Ignore on this machine | append `.mallet/` to `git config --global core.excludesFile`, defaulting to `~/.config/git/ignore` when unset — git reads that path automatically. Grep for an existing entry first; never duplicate. |
| Ignore in specific repos | append `.mallet/` to each `<repo>/.git/info/exclude` |
| Commit it | write nothing. Mention `~/.claude/templates/mallet-gitignore` as a template they can copy in by hand to exclude transient files. |
| Decide later | write nothing |

Never edit a tracked `.gitignore`. If the user has already ignored `.mallet/` globally, say so and skip the question.

---

## 5. Migrate

Per repo, resolve the historical payload so the `CLAUDE.md` strip is exact rather than heuristic:

```bash
curl -sfL "https://raw.githubusercontent.com/<recorded-repo>/<sha>/CLAUDE.md" -o /tmp/mallet-payload-<sha>.md
```

Cache per SHA — repos commonly share one. Two fallbacks:

- `recorded-repo` is `-` (the schema-broken variant): use the repo the install flow was given, or ask.
- Fetch fails, or `sha` is `unknown`: run without `--payload`. The script then skips the `CLAUDE.md` strip rather than guessing, and reports it. Offer to strip by known `##` heading set instead, showing the diff first.

Then:

```bash
bash ~/.claude/skills/migrate/migrate-repo.sh <repo> --payload /tmp/mallet-payload-<sha>.md --yes
```

Run without `--yes` first if the user wants to see the plan for a repo. Relay each repo's output; do not summarise away a `SKIPPED (tracked)` line.

After each repo, verify before moving on:

```bash
git -C <repo> status --porcelain
```

Nothing unexpected should appear. If something does, stop and report — the backup exists, but a half-migrated repo is worse than an unmigrated one.

---

## 6. Report

Per repo: moved, deleted, pruned, stripped, skipped, and the backup path. Then:

- count migrated versus skipped
- every tracked file left in place, so the user has the full list
- the VCS choice applied, if any
- a reminder that `~/.claude/framework.json` is now the single source of version truth

If any repo failed, say which and why. Do not report partial success as success.
