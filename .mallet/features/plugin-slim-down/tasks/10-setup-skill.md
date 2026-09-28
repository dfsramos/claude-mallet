# Task: setup-skill
Status: pending
Deps: 09

## Goal
Provide `/mallet:setup` to install the statusline and fold legacy memory files into auto memory.

## Steps
1. Create `skills/setup/SKILL.md` (`disable-model-invocation: true`): copy `${CLAUDE_SKILL_DIR}/../../statusline/statusline.sh` to `~/.claude/mallet-statusline.sh`, then add or replace `statusLine` in `~/.claude/settings.json` with Edit after backing up; never touch other keys.
2. Offer, per current repo, to fold `.mallet/memory.md` and `.mallet/lessons.md` into auto memory entries; never delete the source files.
3. Remove the transition stub `~/.claude/skills/migrate/detect.sh` directory if task 11 left it and it contains no SKILL.md.
4. Test via fake HOME: statusLine set, other settings keys byte-identical.
