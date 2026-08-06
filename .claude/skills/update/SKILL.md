---
name: update
description: Invoke when the user says "update the framework", "update Mallet", "upgrade Claude Mallet", or "update from <url>". Also invoke when a session-start notice reports that a framework update is available.
---
# Framework Update

Mallet is installed once at `~/.claude/`. This updates that single install — there is nothing per-repo to update, which is the whole point of the user-level layout.

## What this touches

| Path | Treatment |
|---|---|
| `~/.claude/skills/*`, `agents/*`, `templates/*`, `hooks/*` | replaced **per entry** |
| `~/.claude/statusline.sh`, `~/.claude/CLAUDE.md` | replaced |
| `~/.claude/settings.json` | **merged**, never replaced |
| `~/.claude/framework.json` | rewritten, including its `manifest` |
| Any entry under `~/.claude/skills\|agents\|templates\|hooks` the manifest does not claim | left alone, reported as preserved |
| Every `<repo>/.mallet/` | never touched |
| Every `<repo>/.claude/settings.json` and `settings.local.json` | never touched |

Two rules the mechanics enforce, both learned the hard way:

- **Never `rm -rf` a container directory.** `~/.claude/skills/` holds user-authored skills next to Mallet's. Removing the directory destroys them.
- **Never overwrite `~/.claude/settings.json`.** It holds `model`, `effortLevel`, `enabledPlugins`, and the user's own hooks.

---

## 1. Resolve the source

If the user supplied a GitHub URL, extract `owner` and `repo`. Otherwise read `~/.claude/framework.json` and use `.repo`.

If that file does not exist, stop:

> "No user-level Mallet install found at `~/.claude/`. Run a fresh install from `install.md` instead."

If a supplied URL disagrees with the recorded repo, warn and wait for confirmation. A recorded pre-rename name still resolves — GitHub redirects renamed repositories.

---

## 2. Check the latest version

```bash
BRANCH=$(curl -sf "https://api.github.com/repos/{owner}/{repo}" | jq -r '.default_branch')
NEW_SHA=$(curl -sf "https://api.github.com/repos/{owner}/{repo}/commits/${BRANCH}" | jq -r '.sha')
```

Compare against `.version` in `~/.claude/framework.json`. If equal, stop without writing anything:

> "Already up to date (version: {short_sha}). No changes made."

If either call fails, stop and report. Never proceed to the payload steps on a failed version check.

---

## 3. Download and extract

```bash
WORK=/tmp/claude-mallet-update
rm -rf "$WORK"; mkdir -p "$WORK"
curl -sfL "https://github.com/{owner}/{repo}/archive/${NEW_SHA}.tar.gz" -o "$WORK/tarball.tar.gz"
tar -xzf "$WORK/tarball.tar.gz" -C "$WORK" --strip-components=1
```

If `$WORK/.claude/` or `$WORK/CLAUDE.md` is missing, stop and report the download failure.

---

## 4. Back up

```bash
tar -czf "$HOME/.claude/mallet-preupdate-backup-$(date +%Y%m%d%H%M%S).tar.gz" \
  -C "$HOME/.claude" settings.json CLAUDE.md skills agents templates hooks statusline.sh framework.json 2>/dev/null
```

Missing members are fine. Report the path.

---

## 5. Install the payload

```bash
bash "$WORK/.claude/install-payload.sh" --from "$WORK" --repo "{owner}/{repo}" --sha "$NEW_SHA"
```

This performs per-entry replacement, reconciles the previous manifest (removing only what this release dropped), restores executable bits, and rewrites `framework.json` with a fresh manifest. Relay its `removed:` and `preserved:` lines verbatim — the preserved list is how the user confirms their own skills survived.

---

## 6. Merge settings

```bash
bash "$WORK/.claude/merge-settings.sh" "$WORK/.claude/settings.fragment.json"
```

Only Mallet-owned hook entries and `statusLine` are touched. The script backs up `settings.json` first and refuses to run against a corrupt one.

---

## 7. Legacy sweep

```bash
bash "$HOME/.claude/skills/migrate/detect.sh"
```

If any legacy per-project install is reported, list them and note that `/migrate` will clean them up. Do not act unless the user asks.

---

## 8. Cleanup and summary

```bash
rm -rf /tmp/claude-mallet-update
```

Print:

```
── Update complete ──────────────────────────────────────────

  Version:    {old_short_sha} → {new_short_sha}
  Replaced:   {n} entries
  Removed:    {names, or none}
  Preserved:  {names, or none}
  Backup:     {path}
  Legacy:     {n} per-project installs still present, or none

────────────────────────────────────────────────────────────
```

If any step failed, say which and stop. Do not report a partial update as complete.
