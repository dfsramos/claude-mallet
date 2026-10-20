# Claude Mallet — source repository

This repository is both a Claude Code plugin marketplace (`.claude-plugin/marketplace.json`) and the `mallet` plugin (`plugin/`). The conventions below apply to every change here; `.claude/rules/hooks.md` adds the ones for hook and statusline code.

## Layout

- `plugin/` is the payload, the source of truth for what ships: `agents/`, `evals/`, `hooks/`, `persona/`, `rules/`, `skills/`, `statusline/`, plus `plugin/.claude-plugin/plugin.json`. The marketplace manifest points at it as `./plugin`.
- The persona users receive is `plugin/persona/PERSONA.md`, injected by `plugin/hooks/persona.sh`. It is not loaded from this file.
- `.claude/skills/` holds this repo's own maintenance skills (`harvest`, `self-assessment`), which ship nowhere; `.claude/rules/` holds this repo's own rules; `.claude/settings.local.json` is this repo's permissions.
- `.mallet/` is this repo's own state and ships nowhere: `features/`, `discovery-*.md`, the relevance and eval write-ups, and `missions/` until its last file is archived.
- Here the Mallet skills are source, not an installed plugin: edit `plugin/skills/` directly. The `reviewing-sessions` rule against editing Mallet skills, and its routing of amendments to `.claude/rules/`, applies to installed copies only.
- A new plugin skill goes to `plugin/skills/<name>/`; a skill for this repo only goes to `.claude/skills/<name>/`.

## Transition code

- `.claude/install-payload.sh`, `.claude/merge-settings.sh`, and `.claude/settings.fragment.json` exist only so that installed pre-plugin `update` skills can transition to the plugin. Keep their paths and flags stable; `docs/structure.md` records when they and the rest of the transition code can be retired.
- This root `CLAUDE.md` must keep existing: those older `update` skills abort when the downloaded archive has none.

## Paths in skill and doc text

Skills and docs describe the installed plugin layout: `${CLAUDE_PLUGIN_ROOT}` (the plugin's root at runtime), `${CLAUDE_PLUGIN_DATA}` (persistent per-plugin data), and `${CLAUDE_SKILL_DIR}` (the running skill's own directory), never the bare `plugin/` path those files occupy here. Skills and agents are referenced in their namespaced runtime form, `/mallet:<name>` and `mallet:<name>`. One exception: the scripts in `plugin/skills/migrate/` reference `<repo>/.claude/skills/` and `<repo>/.claude/agents/` unprefixed, because they detect the legacy per-project payload that old installs left in target repos.

## Ignore policy

`.mallet/` is re-included in this repo's `.gitignore` (`!.mallet/`) because feature plans are committed to `master` deliberately so they stay visible from every branch; the in-tree file overrides a machine-wide `.mallet/` exclude. Do not add a `.mallet/.gitignore` here, and do not ship one from the plugin: whether `.mallet/` is tracked is each user's decision (`plugin/skills/migrate/mallet-gitignore` is an opt-in template only).

## Tests

`tests/*.sh` cover executable code: hooks, the statusline, scripts that edit user files, and plugin structure. Skill prose is not shell-tested. The suites derive the repo root from `BASH_SOURCE`, use `mktemp -d` for scratch, and override `HOME` so the real `~/.claude/` is never read or written. `bash tests/run.sh` prints one line per suite and exits non-zero if any failed. Some suites exist only for transitional code and go with it: `test-01-merge.sh` and `test-17-transition.sh` with the `.claude/` transition scripts, `test-05-migrate.sh` and `test-07-legacy.sh` with the `migrate` skill.

## Docs parity

A change under `plugin/` updates the matching file in `docs/` in the same commit: skills → `docs/skills.md`, hooks → `docs/hooks.md`, structure → `docs/structure.md`, the persona → `docs/directives.md`. The README's skill, agent and hook tables follow the same rule.

## Changelog

Colleagues use the plugin, and it has no `version` field (a forgotten bump would withhold changes), so `CHANGELOG.md` is how they learn what an update brings. Any commit that changes what a user gets (persona, hook, skill, agent model or effort, statusline, a default) adds a line under today's date in the same commit, written for the user: what changed, what it costs, and anything to do after updating. Internal changes (tests, this repo's docs, `.mallet/`, `.claude/`) get no entry.

## Session records

Session wrap-ups are conversational: no session summary or retrospective file is written to disk. Work that continues across sessions is carried by auto memory `project` entries, not by mission files.

## Git

- Commit directly to `master`. No feature branches and no PRs here; the `b/` and `f/` naming in `plugin/rules/git.md` does not apply.
- Commit message: a one-line subject with no body, imperative verb, capital first letter, ending with a period, e.g. `Add password reset email template.` Trailer lines such as `Co-Authored-By` go below it.
- Run `bash tests/run.sh` before committing a change to hooks, the statusline, or the transition scripts.
- Ask before pushing: colleagues auto-update from `master`, so a push changes what they get.
