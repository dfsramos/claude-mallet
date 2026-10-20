# Claude Mallet — source repository

This repository is both a Claude Code plugin marketplace (`.claude-plugin/marketplace.json`) and the `mallet` plugin (`plugin/`). Read `.mallet/conventions.md` before changing anything here.

- The persona users receive is `plugin/persona/PERSONA.md`, injected by `plugin/hooks/persona.sh`. It is not loaded from this file.
- `.claude/install-payload.sh`, `.claude/merge-settings.sh`, and `.claude/settings.fragment.json` exist only so that installed pre-plugin `update` skills can transition to the plugin. Keep their paths and flags stable.
- This root `CLAUDE.md` must keep existing: those older `update` skills abort when the downloaded archive has none.

## Git

- Commit directly to `master`. No feature branches and no PRs here; the `b/` and `f/` naming in `plugin/rules/git.md` does not apply.
- Commit message: a one-line subject with no body, imperative verb, capital first letter, ending with a period, e.g. `Add password reset email template.` Trailer lines such as `Co-Authored-By` go below it.
- Run `bash tests/run.sh` before committing a change to hooks, the statusline, workflows, or the transition scripts.
- Ask before pushing: colleagues auto-update from `master`, so a push changes what they get.
