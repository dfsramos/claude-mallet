---
name: setup
description: Runs only from /mallet:setup (or /setup), right after installing the plugin or to install the Mallet statusline.
disable-model-invocation: true
allowed-tools: Bash(mkdir -p ${CLAUDE_PLUGIN_DATA}) Bash(cp ${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh ${CLAUDE_PLUGIN_DATA}/statusline.sh) Bash(jq *)
---
# Mallet Setup

One-time setup for what a plugin cannot configure by itself. Each step is independent — skip any the user declines, and report what was done at the end.

---

## 1. Statusline

Plugins cannot set the main `statusLine`, so it is registered in `~/.claude/settings.json`, pointing at a copy the plugin's session-start hook keeps current:

1. Create the copy now, so it works before the next session start:
   ```bash
   mkdir -p ${CLAUDE_PLUGIN_DATA}
   cp ${CLAUDE_PLUGIN_ROOT}/statusline/statusline.sh ${CLAUDE_PLUGIN_DATA}/statusline.sh
   ```
2. Read `~/.claude/settings.json` (treat a missing file as `{}`; stop if it is not valid JSON). If `statusLine` already exists and does not point at a Mallet statusline, show it and ask before replacing it.
3. Back up the file to `~/.claude/settings.json.bak-mallet-setup`, then set only this key, leaving every other key untouched:
   ```json
   "statusLine": { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_DATA}/statusline.sh\"" }
   ```
   Write the expanded path, not the placeholder. Verify with `jq -e . ~/.claude/settings.json` afterwards.

The statusline also records the live model and effort level for the calibrate hook; without it, calibrate falls back to the `effortLevel` in settings.

## 2. Auto-update

Background auto-update is off by default for third-party marketplaces and cannot be enabled from here. Tell the user: `/plugin` → **Marketplaces** → **claude-mallet** → **Enable auto-update**. Without it, `/plugin marketplace update claude-mallet` fetches new versions.

## 3. Legacy Mallet memory files

If the current project has `.mallet/memory.md` or `.mallet/lessons.md` from an earlier Mallet version, offer to fold them into auto memory: each fact becomes a `project` or `reference` memory and each lesson a `feedback` memory, skipping anything already recorded or already covered by the persona. Never delete or edit the source files — tell the user they can remove them once satisfied.

## 4. Transition leftovers

If `~/.claude/skills/migrate/` contains only `detect.sh` and a `MALLET-TRANSITION-STUB` marker (left by the move to the plugin so older update runs finish cleanly), offer to remove that directory. Do not remove it if it contains anything else.

## 5. Report

One line per step: done, skipped, or not applicable.
