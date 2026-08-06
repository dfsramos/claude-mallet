# Task: install-rewrite
Status: done
Deps: 01, 05

## Goal
Rewrite `install.md` to install into `~/.claude/` without destroying the user's existing personal config, and to offer legacy cleanup as part of the flow.

## Context
Two things in the current installer are safe per-repo but destructive at user level.

`install.md:46` runs `rm -rf .claude/agents .claude/hooks .claude/skills .claude/templates`. Pointed at `~/.claude/skills/` that deletes skills Mallet does not own — this machine has a user-authored `backburner` skill living there right now. The installer must remove only the entries present in the payload, never the containing directory.

`install.md:46` also removes `.claude/settings.json` and `CLAUDE.md`. At user level those hold `model`, `effortLevel`, `enabledPlugins`, notify hooks, and possibly personal directives. Settings are merged instead (task 01); `CLAUDE.md` is backed up and confirmed.

Because per-entry replacement leaves no record of what Mallet owns, `framework.json` gains a manifest. Without it, a skill removed from a later Mallet release would linger in `~/.claude/skills/` forever.

## Steps

Rewrite `install.md` end to end with these sections:

1. **Resolve the repo** — unchanged from the current step 1.

2. **Fetch the latest commit** — unchanged from the current step 2.

3. **Download and extract** — unchanged from the current step 3. Validate that `$WORK/.claude/` and `$WORK/CLAUDE.md` both exist; stop and report otherwise.

4. **Confirm the target.** Replace the current `pwd` confirmation with a statement that the install target is `~/.claude/` and is machine-wide, affecting every project. List what will be written and what will be backed up. Wait for explicit confirmation.

5. **Back up the existing user config:**
   ```bash
   tar -czf "$HOME/.claude/mallet-preinstall-backup-$(date +%Y%m%d%H%M%S).tar.gz" \
     -C "$HOME/.claude" settings.json CLAUDE.md skills agents templates hooks statusline.sh 2>/dev/null
   ```
   Missing members are fine. Report the path.

6. **Handle an existing `~/.claude/CLAUDE.md`.** If present, compare it against the payload's `CLAUDE.md`. If it differs, it may hold personal directives: copy it to `~/.claude/CLAUDE.md.pre-mallet-<YYYYMMDD>`, tell the user the path, and note that anything project-specific belongs in that project's `.mallet/conventions.md`. Require confirmation before overwriting.

7. **Install the payload per entry, never per directory:**
   ```bash
   mkdir -p "$HOME/.claude/skills" "$HOME/.claude/agents" "$HOME/.claude/templates" "$HOME/.claude/hooks"

   for kind in skills agents templates hooks; do
     for entry in "$WORK/.claude/$kind"/*; do
       [ -e "$entry" ] || continue
       name=$(basename "$entry")
       rm -rf "$HOME/.claude/$kind/$name"
       cp -r "$entry" "$HOME/.claude/$kind/$name"
     done
   done

   cp "$WORK/.claude/statusline.sh" "$HOME/.claude/statusline.sh"
   cp "$WORK/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
   ```
   State explicitly in the document that `$HOME/.claude/skills`, `agents`, `templates`, and `hooks` are never removed wholesale, because they may hold user-authored entries.

8. **Remove orphans from a previous Mallet install.** If `~/.claude/framework.json` has a `manifest`, delete any entry it lists that is absent from the new payload. Skip when no manifest exists — a first install has nothing to reconcile.

9. **Merge settings:** `bash "$WORK/.claude/merge-settings.sh" "$WORK/.claude/settings.fragment.json"`.

10. **Restore hook permissions:** `chmod +x "$HOME/.claude/hooks/"*.sh "$HOME/.claude/statusline.sh"`.

11. **Write `~/.claude/framework.json`:**
    ```json
    {
      "repo": "{owner}/{repo}",
      "version": "<NEW_SHA>",
      "installed_at": "<today as YYYY-MM-DD>",
      "manifest": {
        "skills": ["..."], "agents": ["..."],
        "templates": ["..."], "hooks": ["..."]
      }
    }
    ```
    Populate each manifest array from the payload's directory listing.

12. **Offer legacy cleanup.** Run the `migrate` skill's discovery and detection phases. If any legacy per-project install is found, present the table and offer to migrate. If none, say so in one line and continue.

13. **Cleanup:** `rm -rf /tmp/claude-mallet-install`.

14. **Project-type suggestions** — carry over the current step 9 unchanged.

15. **Summary** — adapt the current step 10 block: report the install target as `~/.claude/`, the version, the count of legacy repos migrated, and next steps. Replace "Customise `.claude/project/CLAUDE.md`" with "Create `.mallet/conventions.md` in a project to add project-specific conventions".

## TDD Checklist
- [x] Write failing test: seed `<scratchpad>/fake-home/.claude/` with a `settings.json` carrying `model`/`effortLevel`/notify hooks, a user-authored `skills/backburner/SKILL.md`, and a personal `CLAUDE.md`; run the install flow with `HOME` pointed there
- [x] Confirm the current instructions destroy `skills/backburner/` (red)
- [x] Rewrite `install.md` per the steps above
- [x] Assert `skills/backburner/SKILL.md` survives untouched
- [x] Assert `settings.json` retains `model`, `effortLevel`, and the notify hooks, and gains the 4 base hooks plus `statusLine`
- [x] Assert the personal `CLAUDE.md` was copied to `CLAUDE.md.pre-mallet-<date>` before being replaced
- [x] Assert `framework.json` contains a populated `manifest` for all four kinds
- [x] Orphan removal: add a fake `skills/removed-skill/` recorded in a prior manifest but absent from the payload, re-run, assert it is deleted while `backburner` is not
- [x] Assert `chmod +x` leaves every hook and `statusline.sh` executable
- [x] Idempotency: run twice, assert the second run produces the same tree and does not duplicate hook entries

## Notes
Steps 5, 6, and 12 are the only points that require user interaction. Everything else must be safe to run unattended once confirmed.
