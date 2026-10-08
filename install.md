# Installing Claude Mallet

Claude Mallet ships as a Claude Code plugin, distributed from the `claude-mallet` marketplace this repository hosts (`.claude-plugin/marketplace.json`).

## Install

In Claude Code:

```
/plugin marketplace add dfsramos/claude-mallet
/plugin install mallet@claude-mallet
/mallet:setup
```

`/mallet:setup` registers the statusline, offers to turn on auto-update, and offers to fold any legacy `.mallet/memory.md` or `.mallet/lessons.md` into Claude Code's auto memory. Nothing else needs configuring. The plugin has no version to pin, so you track commits on the marketplace's default branch; [CHANGELOG.md](CHANGELOG.md) lists what each update changes.

**Auto-update** is off by default for third-party marketplaces. `/mallet:setup` can turn it on for you, or do it yourself in either of these ways:

- In a session: `/plugin` → **Marketplaces** → **claude-mallet** → **Enable auto-update**.
- In `~/.claude/settings.json`: add `"autoUpdate": true` to the marketplace's entry under `extraKnownMarketplaces`, keeping its `source`:

  ```json
  "extraKnownMarketplaces": {
    "claude-mallet": {
      "source": { "source": "github", "repo": "dfsramos/claude-mallet" },
      "autoUpdate": true
    }
  }
  ```

Either way, Claude Code updates Mallet in the background after each session starts. Without it, run `/plugin marketplace update claude-mallet` to update on demand.

## Already have Mallet installed?

If Mallet is already on this machine from before it was a plugin — either a user-level install at `~/.claude/` or an older per-project install inside individual repos — see [README.md](README.md#moving-from-the-user-level-install) for the transition steps. Both paths are one-shot and take a backup before changing anything.

## Documentation

- [Project Structure](docs/structure.md)
- [Directives](docs/directives.md)
- [Hooks](docs/hooks.md)
- [Skills](docs/skills.md)
