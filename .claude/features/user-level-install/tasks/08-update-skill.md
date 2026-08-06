# Task: update-skill
Status: done
Deps: 01

## Goal
Rewrite `.claude/skills/update/SKILL.md` to update the single user-level install, merging settings and reconciling the manifest instead of overwriting directories.

## Context
The current skill mirrors the per-repo installer: `update/SKILL.md:63` runs `rm -rf .claude/agents .claude/hooks .claude/skills .claude/templates .claude/statusline.sh .claude/settings.json CLAUDE.md`, then copies. Pointed at `~/.claude/` that deletes the user's own skills — `backburner` lives there — and destroys `model`, `effortLevel`, `enabledPlugins`, and notify hooks.

This is also where the drift problem finally closes: eight installs across three versions existed because the update was per repo. One install means one update.

## Steps

Rewrite `.claude/skills/update/SKILL.md`:

1. **Frontmatter** — keep trigger-conditions-only phrasing. Add "update Mallet", "upgrade the framework". Drop any wording implying a per-project target.

2. **Managed paths section** — replace the current list (`update/SKILL.md:9-11`) with:
   - Replaced per entry: `~/.claude/skills/*`, `~/.claude/agents/*`, `~/.claude/templates/*`, `~/.claude/hooks/*`, `~/.claude/statusline.sh`, `~/.claude/CLAUDE.md`
   - Merged, never replaced: `~/.claude/settings.json`
   - Rewritten: `~/.claude/framework.json` including its `manifest`
   - Never touched: every `<repo>/.mallet/`, every `<repo>/.claude/settings.local.json`, every `<repo>/.claude/settings.json`, and any user-authored entry under `~/.claude/skills|agents|templates|hooks` that the manifest does not list

3. **Resolve the source** — read `~/.claude/framework.json` and use `.repo`. If the file is missing, stop and direct the user to `install.md`. Keep the existing behaviour of warning when a supplied URL disagrees with the recorded repo (`update/SKILL.md:25`).

4. **Version check** — compare the GitHub HEAD SHA against `.version` and short-circuit when equal, as today (`update/SKILL.md:38`).

5. **Back up before writing** — same `tar` as the installer, to `~/.claude/mallet-preupdate-backup-<timestamp>.tar.gz`.

6. **Install the payload per entry** — reuse the exact loop from `install.md` step 7. Never `rm -rf` a container directory.

7. **Reconcile the manifest** — diff the previous `manifest` against the new payload listing; delete entries the manifest claimed but the new payload no longer contains; leave unlisted entries alone. Report both the removed and the preserved-unlisted names, so a user-authored skill is visibly accounted for.

8. **Merge settings** — `bash "$WORK/.claude/merge-settings.sh" "$WORK/.claude/settings.fragment.json"`.

9. **Restore permissions** — `chmod +x "$HOME/.claude/hooks/"*.sh "$HOME/.claude/statusline.sh"`.

10. **Write `~/.claude/framework.json`** with the new SHA, today's date, and a regenerated manifest.

11. **Legacy sweep** — run the `migrate` skill's detection phase and report any legacy per-project install found, without acting unless the user asks.

12. **Cleanup** — `rm -rf /tmp/claude-mallet-update`.

13. **Summary** — old and new short SHAs, counts of entries replaced/removed/preserved, the backup path, and any legacy repos still outstanding.

## TDD Checklist
- [x] Write failing test: fake `HOME` holding a Mallet install at an older SHA, a user-authored `skills/backburner/`, a `settings.json` with personal keys, and a manifest listing a skill absent from the new payload
- [x] Confirm the current instructions delete `skills/backburner/` (red)
- [x] Rewrite the skill
- [x] Assert `backburner` survives and is reported as preserved-unlisted
- [x] Assert the manifest-listed orphan is removed
- [x] Assert `settings.json` keeps `model`, `effortLevel`, `enabledPlugins`, and notify hooks
- [x] Assert `framework.json` carries the new SHA and a regenerated manifest
- [x] Assert the version check short-circuits with no writes when the SHA already matches
- [x] Assert a mid-run `curl` failure leaves the existing install intact
- [x] Idempotency: run twice at the same SHA, assert the second run is a no-op

## Notes
Steps 6 and 7 are shared with `install.md`. If the loop is edited in one place, edit both — or extract it to `.claude/install-payload.sh` and have both documents call it, which is the preferred outcome if the duplication survives review.
