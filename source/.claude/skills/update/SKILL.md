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

If no URL was provided, read `.claude/framework.json` and use the `repo` field directly.

---

## 2. Check Current Installation

Read `.claude/framework.json`. If it does not exist, stop and tell the user:

> "No framework installation found in this directory. Run a fresh install instead."

Extract `repo` and `version` (the installed commit hash) from the file.

If a URL was provided and the `repo` field does not match it, warn the user and wait for confirmation before continuing.

---

## 3. Clone to a Temporary Directory

The clone directory is always `/tmp/ai-framework-update`. Remove any leftover from a prior run first, then clone:

```bash
rm -rf /tmp/ai-framework-update
git clone --depth=1 "https://github.com/{owner}/{repo}.git" /tmp/ai-framework-update
```

If the clone fails, report the error and stop.

Capture the new commit hash:

```bash
git -C /tmp/ai-framework-update rev-parse HEAD
```

If the new hash matches the installed hash, stop and tell the user:

> "Already up to date (version: {short_hash}). No changes were made."

Clean up and exit:

```bash
rm -rf /tmp/ai-framework-update
```

---

## 4. Assess Changes

From the project root, run a single recursive diff to identify which files differ:

```bash
diff -rq /tmp/ai-framework-update/source .
```

This reports:
- `Only in /tmp/ai-framework-update/source/...` → `NEW`: will be added
- `Files ... and ... differ` → needs classification (see step 5)
- Files not mentioned → `SAME`: no action needed

**Important:** Do not use any Bash commands that assign shell variables (e.g. `VAR=...`, `arr=(...)`). Use only direct commands with literal paths.

---

## 5. Classify Conflicts and Resolve Autonomously

For each file flagged as differing, run:

```bash
diff /tmp/ai-framework-update/source/<relative-path> ./<relative-path>
```

Then apply the following decision logic. **Do not pause to ask the user** unless the conflict meets the escalation criteria below.

### Auto-merge (proceed without asking)

Apply these resolutions silently:

- **Local is a superset** — local has everything upstream has, plus additional content (new sections, extra entries, appended lines). Keep local additions; apply any upstream changes to shared content.
- **Upstream-only addition** — upstream adds new content that local does not have; local has not removed or changed the surrounding context. Apply the upstream addition.
- **Minor wording/phrasing** — the only difference is cosmetic (punctuation, capitalisation, a rephrased sentence with the same meaning). Take the upstream version.
- **Whitespace/line-endings only** — content is semantically identical. Take the upstream version.

### Escalate to user (pause and ask)

Only stop for:

- **Local removed upstream content** — local is missing steps, sections, or instructions that exist upstream, suggesting deliberate removal of functionality.
- **Structural divergence** — the file has been substantially reorganised locally such that a clean merge is not obvious.
- **Conflicting intent** — both sides changed the same passage in incompatible ways that would result in contradictory instructions if naively merged.

When escalating, show the relevant diff excerpt and ask specifically:

> "Local `{file}` is missing upstream content. Keep local version, take upstream, or merge? Show me the diff if unsure."

---

## 6. Show Pre-flight Summary and Proceed

Present a brief summary, then immediately proceed without waiting for confirmation:

```
Current version:  {installed_short_hash}
Latest version:   {new_short_hash} ({date of new commit})

Plan:
  Updated (identical/whitespace):  N file(s)
  Auto-merged (additive):          N file(s)
  Added (new files):               N file(s)
  Escalated (requires input):      N file(s)  ← only shown if > 0
```

If there are escalated files, resolve them before proceeding to installation.

---

## 7. Install Updated Files

For each file (respecting the resolutions from step 5):

- Read from `/tmp/ai-framework-update/source/<relative-path>` using the Read tool
- **New files (Added):** Write to `<current-directory>/<relative-path>` using the Write tool
- **Existing files (Updated/Merged):** Use Edit to apply only the changed content — do not rewrite the entire file with Write
- For auto-merged files: apply each upstream addition or change as a targeted Edit
- Log: `Updated:`, `Merged:`, `Added:`, or `Skipped:` per file

Do not use Bash for file copying — use Read + Write/Edit per file.

---

## 8. Update Framework Metadata

Overwrite `.claude/framework.json`:

```json
{
  "repo": "{owner}/{repo}",
  "version": "<new full commit hash>",
  "installed_at": "<today's date as YYYY-MM-DD>"
}
```

---

## 9. Set Hook Permissions

For every `.sh` file under `.claude/hooks/`, run:

```bash
chmod +x <file>
```

---

## 10. Remove Temporary Directory

```bash
rm -rf /tmp/ai-framework-update
```

---

## 11. Summary

```
── Update complete ──────────────────────────────────────────

  Version:  {installed_short_hash} → {new_short_hash} ({date})
  Updated:  N file(s)
  Merged:   N file(s)
  Added:    N file(s)
  Skipped:  N file(s)

────────────────────────────────────────────────────────────
```
