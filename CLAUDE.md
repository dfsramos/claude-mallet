# Claude Mallet — source repository

This repository is both a Claude Code plugin marketplace (`.claude-plugin/marketplace.json`) and the `mallet` plugin (`plugin/`). The conventions below apply to every change here; `.claude/rules/hooks.md` adds the ones for hook and statusline code.

## Layout

- `plugin/` is the payload, the source of truth for what ships: `agents/`, `evals/`, `hooks/`, `persona/`, `rules/`, `skills/`, `statusline/`, plus `plugin/.claude-plugin/plugin.json`. The marketplace manifest points at it as `./plugin`.
- The persona users receive is `plugin/persona/PERSONA.md`, injected by `plugin/hooks/persona.sh`. It is not loaded from this file.
- `.claude/skills/` holds this repo's own maintenance skills (`harvest`, `self-assessment`), which ship nowhere; `.claude/rules/` holds this repo's own rules; `.claude/settings.local.json` is this repo's permissions.
- `.mallet/` is this repo's own state and ships nowhere: `features/`, `discovery-*.md`, the relevance and eval write-ups, and `missions/archive/`, the closed mission files of the mission mechanism retired 2026-10-20.
- Here the Mallet skills are source, not an installed plugin: edit `plugin/skills/` directly. The `reviewing-sessions` rule against editing Mallet skills, and its routing of amendments to `.claude/rules/`, applies to installed copies only.
- A new plugin skill goes to `plugin/skills/<name>/`; a skill for this repo only goes to `.claude/skills/<name>/`.

## Paths in skill and doc text

Skills and docs describe the installed plugin layout: `${CLAUDE_PLUGIN_ROOT}` (the plugin's root at runtime), `${CLAUDE_PLUGIN_DATA}` (persistent per-plugin data), and `${CLAUDE_SKILL_DIR}` (the running skill's own directory), never the bare `plugin/` path those files occupy here. Skills and agents are referenced in their namespaced runtime form, `/mallet:<name>` and `mallet:<name>`.

## Ignore policy

`.mallet/` is re-included in this repo's `.gitignore` (`!.mallet/`) because feature plans are committed to `master` deliberately so they stay visible from every branch; the in-tree file overrides a machine-wide `.mallet/` exclude. Do not add a `.mallet/.gitignore` here, and do not ship one from the plugin: whether `.mallet/` is tracked is each user's decision.

## Tests

`tests/*.sh` cover executable code: hooks, the statusline, scripts that edit user files, and plugin structure. Skill prose is not shell-tested. The suites derive the repo root from `BASH_SOURCE`, use `mktemp -d` for scratch, and override `HOME` so the real `~/.claude/` is never read or written. `bash tests/run.sh` prints one line per suite and exits non-zero if any failed.

## Docs parity

A change under `plugin/` updates the matching file in `docs/` in the same commit: skills → `docs/skills.md`, hooks → `docs/hooks.md`, structure → `docs/structure.md`, the persona → `docs/directives.md`. The README's skill, agent and hook tables follow the same rule.

## Changelog

Colleagues use the plugin, and it has no `version` field (a forgotten bump would withhold changes), so `CHANGELOG.md` is how they learn what an update brings. Any commit that changes what a user gets (persona, hook, skill, agent model or effort, statusline, a default) adds a line under today's date in the same commit, written for the user: what changed, what it costs, and anything to do after updating. Internal changes (tests, this repo's docs, `.mallet/`, `.claude/`) get no entry.

## Session records

Session wrap-ups are conversational: no session summary or retrospective file is written to disk. Work that continues across sessions is carried by auto memory `project` entries, not by mission files.

## Git

- Commit directly to `master`. No feature branches and no PRs here; the `b/` and `f/` naming in `plugin/rules/git.md` does not apply.
- Commit message: a one-line subject with no body, imperative verb, capital first letter, ending with a period, e.g. `Add password reset email template.` Trailer lines such as `Co-Authored-By` go below it.
- Run `bash tests/run.sh` before committing a change to hooks or the statusline.
- Ask before pushing: colleagues auto-update from `master`, so a push changes what they get.

## Quarterly prune

Native Claude Code absorbs what this plugin does, piece by piece (`.mallet/relevance-2026-10-19.md` records the first round). Every three months, read the Claude Code changelog since the last prune and ask of each remaining hook, skill, agent and persona rule whether a native feature or an official plugin now covers it. Drop what is covered rather than keep a Mallet copy, and adopt an official plugin over re-implementing one. Record each prune here. Last prune: 2026-10-20. Next due: 2027-01-19; it also decides `council` and `adr`, on probation since 2026-10-20 because they are unique but were unused.
