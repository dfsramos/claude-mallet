---
name: update
description: Invoke when the user says "update the framework", "update from <url>", or asks to upgrade the AI framework to the latest version. Requires a GitHub URL to the framework repository.
---
# Framework Update

Replace framework-managed files with the latest version from the remote repository. This is a **source-of-truth update** — local edits to framework files are discarded. User content is preserved in:

- `.claude/project/**` — all project-scoped context, skills, memory, missions
- `.claude/settings.local.json` — user permissions and local overrides
- `.claude/framework.json` — updated at the end with the new version

Everything else framework-owned (`.claude/hooks/`, `.claude/skills/`, `.claude/templates/`, `.claude/statusline.sh`, `.claude/settings.json`, root `CLAUDE.md`) is overwritten wholesale.

---

## 1. Resolve the Repo

If the user provided a GitHub URL (`https://github.com/{owner}/{repo}`), extract `owner` and `repo`.

Otherwise, read `.claude/framework.json` and use its `repo` field (format `{owner}/{repo}`). If the file does not exist, stop:

> "No framework installation found here. Run a fresh install instead."

If a URL was provided and it does not match `framework.json.repo`, warn and wait for confirmation before continuing.

---

## 2. Check Latest Version

Query the default branch and its HEAD commit via the GitHub API:

```bash
BRANCH=$(curl -sf "https://api.github.com/repos/{owner}/{repo}" | jq -r '.default_branch')
NEW_SHA=$(curl -sf "https://api.github.com/repos/{owner}/{repo}/commits/${BRANCH}" | jq -r '.sha')
```

Compare `NEW_SHA` against `framework.json.version`. If they match, stop:

> "Already up to date (version: {short_sha}). No changes made."

---

## 3. Download and Extract

```bash
WORK=/tmp/ai-framework-update
rm -rf "$WORK"
mkdir -p "$WORK"
curl -sfL "https://github.com/{owner}/{repo}/archive/${NEW_SHA}.tar.gz" -o "$WORK/tarball.tar.gz"
tar -xzf "$WORK/tarball.tar.gz" -C "$WORK" --strip-components=1
```

After extraction, `$WORK/source/` contains the new framework tree. If the directory is missing, stop and report the download failure.

---

## 4. Replace Framework-Managed Files

From the project root:

```bash
rm -rf .claude/hooks .claude/skills .claude/templates .claude/statusline.sh .claude/settings.json CLAUDE.md

cp -r "$WORK/source/.claude/hooks" "$WORK/source/.claude/skills" "$WORK/source/.claude/templates" .claude/
cp "$WORK/source/.claude/statusline.sh" "$WORK/source/.claude/settings.json" .claude/
cp "$WORK/source/CLAUDE.md" ./CLAUDE.md
```

`.claude/project/**`, `.claude/settings.local.json`, and `.claude/framework.json` are untouched.

---

## 5. Restore Hook Permissions

```bash
chmod +x .claude/hooks/*.sh
```

---

## 6. Update Metadata

Overwrite `.claude/framework.json`:

```json
{
  "repo": "{owner}/{repo}",
  "version": "<NEW_SHA>",
  "installed_at": "<today as YYYY-MM-DD>"
}
```

---

## 7. Cleanup and Summary

```bash
rm -rf /tmp/ai-framework-update
```

Print:

```
── Update complete ──────────────────────────────────────────

  Version:  {old_short_sha} → {new_short_sha}

────────────────────────────────────────────────────────────
```
