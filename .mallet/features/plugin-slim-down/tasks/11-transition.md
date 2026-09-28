# Task: transition
Status: done
Deps: 09

## Goal
Make the next `update` run on a user-level install back it up, remove Mallet's copied payload, and hand over to the plugin.

## Steps
1. Rewrite `.claude/install-payload.sh` (same path and flags so installed update skills run it): back up `~/.claude/{skills,agents,templates,hooks,statusline.sh,CLAUDE.md,framework.json,settings.json}`; remove only entries in `framework.json` manifest; remove `~/.claude/CLAUDE.md` only if byte-identical (ignoring CR) to `CLAUDE.md` at the recorded SHA fetched from raw.githubusercontent.com, otherwise leave it and print the path; write `framework.json` `{"transitioned":"plugin","at":…}`; print the two plugin install commands.
2. Rewrite `.claude/merge-settings.sh`: remove Mallet-owned hook registrations and a statusLine pointing at `~/.claude/statusline.sh`; back up first; refuse corrupt JSON (existing behaviour).
3. Leave `~/.claude/skills/migrate/detect.sh` as a stub (no SKILL.md) that prints the plugin install reminder, so update step 7 still succeeds.
4. `settings.fragment.json` shipped empty (`{}`).
5. Tests: fake HOME seeded from the current install layout plus a user-authored skill → after transition, user skill preserved, Mallet entries gone, settings keeps model/permissions/plugins, backup exists; modified CLAUDE.md retained.
