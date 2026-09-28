# Claude Mallet — source repository

This repository is both a Claude Code plugin marketplace (`.claude-plugin/marketplace.json`) and the `mallet` plugin (`plugin/`). Read `.mallet/conventions.md` before changing anything here.

- The persona users receive is `plugin/persona/PERSONA.md`, injected by `plugin/hooks/persona.sh`. It is not loaded from this file.
- `.claude/install-payload.sh`, `.claude/merge-settings.sh`, and `.claude/settings.fragment.json` exist only so that installed pre-plugin `update` skills can transition to the plugin. Keep their paths and flags stable.
- This root `CLAUDE.md` must keep existing: those older `update` skills abort when the downloaded archive has none.
