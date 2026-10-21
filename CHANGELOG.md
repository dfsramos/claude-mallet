# Changelog

What changed for people using the `mallet` plugin: behaviour, cost, defaults, and anything to do after updating. Newest first. The plugin has no version field, so entries are dated; update with `/plugin marketplace update claude-mallet`. Changes before 2026-10-07 are in the git history.

## 2026-10-21

**Added**
- Session start names leftover `.mallet/` files that earlier versions read and nothing has read since 2026-10-20: `conventions.md` (with its line count; Claude reads it and applies it for the session), `overrides/`, `skills/`, `missions/active.md`, and the inert `typecheck.enabled` / `command-guard.enabled` markers. Each line says where the content belongs now (`CLAUDE.md` or `.claude/rules/`, `.claude/rules/<skill>.md`, `.claude/skills/`, auto memory). Claude offers the moves once after your first request; if you decline it creates `.mallet/.leftovers-declined` and the notice stops. Runs on startup and `/clear`, not on resume or compaction. Costs nothing in a project without leftovers; with three of them the notice measured 988 characters, about 250 tokens, once per conversation. Why: `/mallet:migrate` wrote `conventions.md` into every repo it cleaned, and since the 2026-10-20 prune nothing read it, so those project conventions had silently stopped applying. After updating: open each project once and accept the moves, or decline.

## 2026-10-20

**Changed (cost)**
- The persona is a third of its former size: 2,870 characters, measured at 971 input tokens per request against 3,109 before (`claude -p` with and without it; every request re-reads it). What stays was kept on evidence. A plugin eval suite (`plugin/evals/`, seven cases, run on Fable with a Sonnet judge, three runs per arm) scored the trimmed persona at a mean +0.48 over no persona, against +0.31 for the full one. Kept: evidence and no speculation about a resource from its name (+1.00), calm tone (+0.22), the tool preferences, scope and reuse, explicit confirmation before database mutations (+0.33), a rewritten production check that asks whether a remote target is production before any side-effecting command (+1.00; the old wording measured no effect), the `[tentative]`/`[firm]`/`[re-evaluate]` tags, and the wrap-up offer. Dropped because Claude Code's own system prompt covers them or they measured no effect: Interaction Style, Implementation Depth, destructive-operation rules beyond database mutations, Memory and Self-Improvement, Skills, Verification Before Done, Subagents, Task Calibration (the `[calibrate]` line is now informational), and most of Continuity. Section by section in `docs/directives.md`.

**Changed**
- Git conventions moved out of the persona into `plugin/rules/git.md` (same rules: branch per task as `b/…` or `f/…`, PR then switch back, one-line subject ending with a period). In a git repository that states no Git conventions of its own (no heading naming Git in `CLAUDE.md`, `CLAUDE.local.md`, or `.claude/rules/`, there, in a parent directory, or in `~/.claude`), session start prints those defaults for the session (221 tokens) and Claude offers once to copy them to `.claude/rules/git.md`, which Claude Code loads itself from then on. Accept, or write your own Git section; either stops the notice. A project whose `CLAUDE.md` already has a Git section sees nothing new. The `.mallet/features/` exception (plans committed to the default branch directly) is no longer in the rule; `/mallet:plan-feature` still states it.
- `.mallet/conventions.md` and `.mallet/overrides/` are no longer read: the persona section that instructed it is gone. Move their content to `CLAUDE.md` or `.claude/rules/<topic>.md`, which Claude Code loads in every session and re-reads after compaction. An amendment to a Mallet skill becomes `.claude/rules/<skill>.md` with "When running `/mallet:<skill>`, …" lines. `.mallet/skills/` is no longer listed at session start either (see Removed below).
- `/mallet:reviewing-sessions` routes its fixes to native files: new project skills to `.claude/skills/`, project rules and Mallet-skill amendments to `.claude/rules/` (proposed first, written on agreement). It no longer writes `.mallet/skill-backlog.md`; where one exists it actions or drops the items and deletes the file once empty.
- `/mallet:receiving-code-review` now triggers on "apply the reviewer's feedback" and "address review comments". In the eval it never fired on those phrasings before; it now fires every time.
- The plugin ships its eval suite in `plugin/evals/`. It does nothing unless you run `claude plugin eval`.

**Removed**
- Five hooks, each replaced by something native, so no hook runs on your prompts, tool calls, or turn ends any more. `user-prompt-submit.sh`: the session-watch compaction reminder is replaced by the `autoCompactWindow` setting (for example `"autoCompactWindow": 200000` in `~/.claude/settings.json`, or `/autocompact`), which compacts at a chosen context size instead of asking; its `[calibrate]` line is gone with the Task Calibration directive, and the statusline no longer writes the `mallet-calibrate-<session>.json` temp file that fed it. `write-guard.sh`: Claude Code prefers `Edit` over `Write` on an existing file by itself; to keep the prompt before edits to lint or type-check config, add `permissions.ask` rules such as `Edit(//**/.eslintrc*)`, `Edit(//**/tsconfig*.json)`, `Edit(//**/phpstan.neon*)`. `command-guard.sh`: add `Bash(git * --no-verify*)` and `Bash(git commit -n *)` to `permissions.deny`, and the destructive commands you want a prompt for (`Bash(git push --force*)`, `Bash(git reset --hard*)`, `Bash(rm -rf *)`, …) to `permissions.ask`. `typecheck.sh` and `typecheck-stop.sh`: install the official language server plugins instead, `claude plugin install typescript-lsp@claude-plugins-official` and `php-lsp@claude-plugins-official`, which report diagnostics after every edit; they need `typescript-language-server` and `intelephense` on `PATH`. The `.mallet/typecheck.enabled` and `.mallet/command-guard.enabled` markers are inert and can be deleted.
- Six skills. `/mallet:discover`: `/init` writes a project's `CLAUDE.md`, `/doctor` and `/fewer-permission-prompts` cover the setup checks, and the official `claude-code-setup` plugin suggests hooks, skills and MCP servers for a codebase. `/mallet:checkpoint`: `/rewind` restores earlier state within a session, and auto memory carries work across sessions (below). `/mallet:calibrate`, `/mallet:preflight`, `/mallet:hooks-setup`: unused, and the hooks and directive they served are gone. `/mallet:implement-feature`, with the `feature-pipeline` workflow and the agents `feature-analyst`, `code-analyst`, `plan-critic`, `implementer` and `test-runner`: unused in 30 days of sessions. `code-reviewer` (Clifford) and `scope-validator` (Sylvie) stay as standalone agents to dispatch on a change set.
- Mission files. Session start no longer flags `.mallet/missions/active.md`, and `post-compact.sh` no longer prints it after a compaction. `/mallet:reviewing-sessions` records work that continues across sessions in an auto memory `project` entry instead, which Claude Code loads at every session start, and offers to fold a leftover mission file into it and archive the file; `/mallet:next-steps` reads that entry, and any leftover mission file, for pending work.
- Session start no longer lists `.mallet/skills/`. Move project skills to `.claude/skills/`, which Claude Code loads itself; `/mallet:plan-feature` scaffolds knowledge skills there now.

## 2026-10-14

**Fixed**
- On Windows, the transition from the user-level install removed none of Mallet's old skills, agents, templates or hooks, and listed them all as "preserved (not Mallet's)". The native `jq.exe` ends each manifest line with `\r`, so no entry matched a file. The transition now strips it. If you already transitioned on Windows, delete the entries the transition backup's `framework.json` manifest lists from `~/.claude/skills`, `agents`, `templates` and `hooks`; leave `skills/migrate` for `/mallet:setup`.

## 2026-10-08

**Changed (cost)**
- The statusline is two lines: model, effort and branch, then cost, context size, and your 5-hour and 7-day limits. Context now shows in tokens with the window percentage beside it (`ctx 351k (35%)`), since token count is what each turn costs. The prompt count (`T:`) and the cumulative token line are gone: the token line counted each API call two or three times over, and was mostly cache reads anyway. The statusline no longer reads the transcript, so it renders faster on long sessions. Nothing to do after updating; the new statusline arrives with the next session start.
- The session-watch compaction reminder now fires on context size in tokens: at 150k, then at each further 50k (200k, 250k, …). It used to fire on window percentage (60/75/90%) or, without the Mallet statusline, on prompt count. Cost tracks context size because every turn re-reads all of it, and on a 1M window a session could pass 350k tokens without a percentage warning. You also see a one-line notice of your own. Set `CLAUDE_CTX_WARN_THRESHOLD` / `CLAUDE_CTX_WARN_STEP` to change the trigger points. Nothing to do after updating.

**Fixed**
- A plugin update did not reach the statusline when you resumed a session (`claude --resume` or `--continue`); only a fresh start refreshed it. Resuming now refreshes it too. Updates still apply from the session after the one that downloads them.
- The statusline was blank on macOS. It used a bash 4.3 feature that the system bash 3.2 lacks; it now renders there.
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
