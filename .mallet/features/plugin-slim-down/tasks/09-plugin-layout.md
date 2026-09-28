# Task: plugin-layout
Status: done
Deps: 06, 07, 08

## Goal
Restructure the repository so it is both a Claude Code marketplace and the `mallet` plugin.

## Steps
1. `git mv .claude/skills skills`, `.claude/agents agents`, `.claude/hooks hooks`, `.claude/statusline.sh statusline/statusline.sh`, `CLAUDE.md persona/PERSONA.md`. Leave `.claude/install-payload.sh`, `.claude/merge-settings.sh`, `.claude/settings.fragment.json` for task 11.
2. Create `.claude-plugin/plugin.json` (`name: mallet`, `version`, `description`, `repository`) and `.claude-plugin/marketplace.json` (`name: mallet`, owner, one plugin with `source: "./"`).
3. Create `hooks/hooks.json` with SessionStart (startup, compact), UserPromptSubmit, PreToolUse(Write) using `"${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh"`.
4. Add `hooks/persona.sh` on SessionStart `startup|resume|clear|compact` printing `persona/PERSONA.md`. Verify the SessionStart output size cap in hooks.md and that PERSONA.md fits; record in state.md.
5. Remove the GitHub update-check block from session-start.sh (plugin updates replace it); keep legacy per-project detection.
6. Repoint every test's `H=`/path variables; move suites to `tests/` at repo root and update the conventions.md command.
7. Add a new root `CLAUDE.md` for this repo only (project instructions: pointer to `.mallet/conventions.md`), so the persona no longer loads twice here.
8. `claude plugin validate .` passes; `claude --plugin-dir .` session lists `mallet:*` skills and agents; record the exact agent type strings.
