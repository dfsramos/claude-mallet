---
name: update
description: Invoke when the user says "update the framework", "update from <url>", or asks to upgrade the AI framework to the latest version. Requires a GitHub URL to the framework repository.
---
# Framework Update

Update the AI framework in the current project to the latest version from the remote repository.

---

## 1. Resolve the Repo

The user provided a GitHub URL. Extract `owner` and `repo` from it.

Pattern: `https://github.com/{owner}/{repo}`

---

## 2. Check Current Installation

Read `.claude/framework.json`. If it does not exist, stop and tell the user:

> "No framework installation found in this directory. Run a fresh install instead."

Extract `repo` and `version` (the installed commit hash) from the file.

If the `repo` field does not match the repo derived from the URL, warn the user before continuing:

> "The installed framework repo ({installed_repo}) does not match the URL you provided ({url_repo}). Confirm you want to continue."

Wait for confirmation before proceeding.

---

## 3. Clone to a Temporary Directory

```bash
TMPDIR="/tmp/ai-framework-update-$(date +%s)"
git clone --depth=1 "https://github.com/{owner}/{repo}.git" "$TMPDIR"
```

If the clone fails, report the error and stop.

Capture the new commit hash:

```bash
cd "$TMPDIR" && git rev-parse HEAD
```

If the new hash matches the installed hash, stop and tell the user:

> "Already up to date (version: {short_hash}). No changes were made."

Clean up `$TMPDIR` and exit.

---

## 4. Assess Changes

List all files under `$TMPDIR/source/`:

```bash
find "$TMPDIR/source" -type f
```

For each file, derive its relative path (strip `$TMPDIR/source/` prefix) and compare it against the currently installed version:

- **No local file exists** — will be added (new file in this update)
- **Files are identical** — auto-update (safe, no user customisation)
- **Files differ** — flag as a conflict (user may have customised it)

---

## 5. Report and Confirm

Present a pre-flight summary:

```
Current version:  {installed_short_hash}
Latest version:   {new_short_hash} ({date of new commit})

Files to update:  N (identical or new)
Conflicts:        N (local changes detected)

Conflicts:
  - CLAUDE.md — local content differs from upstream
  - [other files...]
```

If there are conflicts, ask:

> "These files differ from the upstream version — they may contain local customisations. How should I handle them?"

Options:
1. **Overwrite all** — replace with upstream versions (local changes lost)
2. **Skip conflicts** — update everything except conflicting files
3. **Review each** — decide file by file (show a diff for each)

If there are no conflicts, proceed without asking.

---

## 6. Install Updated Files

For each file to update (respecting the skip list from step 5):

- Read from `$TMPDIR/source/<relative-path>` using the Read tool
- Write to `<current-directory>/<relative-path>` using the Write tool
- Log: `Updated:` for changed files, `Added:` for new files, `Skipped:` for conflicts preserved

Do not use Bash for file copying — use Read + Write per file.

---

## 7. Update Framework Metadata

Overwrite `.claude/framework.json`:

```json
{
  "repo": "{owner}/{repo}",
  "version": "<new full commit hash>",
  "installed_at": "<today's date as YYYY-MM-DD>"
}
```

---

## 8. Set Hook Permissions

For every `.sh` file under `.claude/hooks/`, run:

```bash
chmod +x <file>
```

---

## 9. Remove Temporary Directory

```bash
rm -rf "$TMPDIR"
```

---

## 10. Summary

```
── Update complete ──────────────────────────────────────────

  Version:  {installed_short_hash} → {new_short_hash} ({date})
  Updated:  N file(s)
  Added:    N file(s)
  Skipped:  N file(s) (conflicts preserved)

────────────────────────────────────────────────────────────
```
