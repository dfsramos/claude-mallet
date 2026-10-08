# Installing Claude Mallet

Claude Mallet ships as a Claude Code plugin, distributed from the `claude-mallet` marketplace this repository hosts (`.claude-plugin/marketplace.json`).

## Install

In Claude Code:

```
/plugin marketplace add dfsramos/claude-mallet
/plugin install mallet@claude-mallet
/mallet:setup
```

`/mallet:setup` registers the statusline, points you at enabling auto-update, and offers to fold any legacy `.mallet/memory.md` or `.mallet/lessons.md` into Claude Code's auto memory. Nothing else needs configuring — the plugin has no version to pin, so you track commits on the marketplace's default branch — [CHANGELOG.md](CHANGELOG.md) lists what each update changes — and background auto-update is off by default for third-party marketplaces (`/plugin` → **Marketplaces** → **claude-mallet** → **Enable auto-update**, or `/plugin marketplace update claude-mallet` on demand).

## Already have Mallet installed?

If Mallet is already on this machine from before it was a plugin — either a user-level install at `~/.claude/` or an older per-project install inside individual repos — see [README.md](README.md#moving-from-the-user-level-install) for the transition steps. Both paths are one-shot and take a backup before changing anything.

## Documentation

- [Project Structure](docs/structure.md)
- [Directives](docs/directives.md)
- [Hooks](docs/hooks.md)
- [Skills](docs/skills.md)
