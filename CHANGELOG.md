# Changelog

What changed for people using the `mallet` plugin: behaviour, cost, defaults, and anything to do after updating. Newest first. The plugin has no version field, so entries are dated; update with `/plugin marketplace update claude-mallet`. Changes before 2026-10-07 are in the git history.

## 2026-10-08

**Changed (cost)**
- The session-watch compaction reminder now fires on context size in tokens: at 150k, then at each further 50k (200k, 250k, …). It used to fire on window percentage (60/75/90%) or, without the Mallet statusline, on prompt count. Cost tracks context size because every turn re-reads all of it, and on a 1M window a session could pass 350k tokens without a percentage warning. You also see a one-line notice of your own. Set `CLAUDE_CTX_WARN_THRESHOLD` / `CLAUDE_CTX_WARN_STEP` to change the trigger points. Nothing to do after updating.

**Fixed**
- The statusline was blank on macOS. It used a bash 4.3 feature that the system bash 3.2 lacks; it now renders all three lines there.
- `/mallet:implement-feature` was hidden behind its own workflow, which shared its name, so its trigger description never reached Claude. The workflow is now `feature-pipeline`; the skill keeps its name.
- `/mallet:adr` numbered the second ADR wrongly once `docs/adr/README.md` existed.
- After a compaction, a long mission file could push the restored state past Claude Code's 10,000-character hook limit, so Claude saw only a preview. The mission is now capped with a truncation notice.
- The typecheck hook (opt-in) could run `npx tsc` without a local TypeScript, which installs an unrelated `tsc` package. It now runs only the project's own `tsc`, also found in a parent directory for monorepo packages, and skips the check otherwise; Yarn PnP projects are skipped. It has a 120-second timeout, and a check the timeout kills runs again at the next turn's end.

**Changed**
- `/mallet:setup` now offers to turn on auto-update for you, by setting `autoUpdate` on the `claude-mallet` marketplace entry in `~/.claude/settings.json`. Turn it on and updates arrive in the background after each session starts. Already set up? Run `/mallet:setup` again, or see [install.md](install.md).
- Persona: `.mallet/conventions.md` now overrides skill instructions as well as the persona. "Ask about file names" no longer applies when a convention or skill already fixes the name. Destructive-operation confirmation still covers deleting files, but no longer treats ordinary edits as overwrites, and `checkpoint`/`reviewing-sessions` may manage `.mallet/missions/` without asking. Independent subagent verification is for non-trivial multi-file changes. Skill ideas go to `.mallet/skill-backlog.md` only where `.mallet/` already exists; elsewhere Claude mentions them once.
- `/mallet:reviewing-sessions` no longer edits Mallet's own skills (a plugin update would overwrite the edit) or your project's `CLAUDE.md`. Skill fixes become overrides in `.mallet/overrides/`, project rules go to `.mallet/conventions.md`, and a `CLAUDE.md` change is proposed to you instead.
- Session start now lists your project skills in `.mallet/skills/`, which Claude Code does not load on its own, and flags an open mission in `.mallet/missions/active.md` with its pending-task count. Both also appear after `/clear`; the skill list also appears after compaction.
- `/mallet:plan-feature` offers to record an ADR once you approve a design that makes a significant architectural choice.
- Command guard (opt-in) now also catches `bash -c "…"` scripts, a quoted default branch (`git push -f origin "main"`), and path-qualified commands (`/usr/bin/git`).
- The statusline and the session-watch prompt counter read the transcript in one streaming pass, which is faster on long sessions.

## 2026-10-07

**Cost**
- The pipeline's planner (Callum), plan critic (Percy), and reviewer (Clifford) run on opus, and the pipeline's last fix attempt escalates to opus.

**Added**
- `/mallet:council`: four independent advisors pressure-test a decision that is expensive to reverse. `plan-feature` and `adr` offer it.
- Command guard, opt-in through `/mallet:hooks-setup`: denies skipping git hooks and force-pushing the default branch, and asks before other hard-to-undo commands.

**Changed**
- Session-watch's compaction prompt is based on context usage rather than prompt count alone.
- Editing a lint or type-check config now asks first, so a failing check gets fixed in the code rather than loosened.
- The typecheck hook checks the files edited in a turn once, at the end of the turn, instead of after every edit.
- Task calibration can recommend handing a bounded part of the work to a subagent on another model instead of switching the session's model.
- The feature pipeline plans and checks tests, reviews beyond the diff, and reads the change set from git.
