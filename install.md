# Installing Claude Mallet

Claude Mallet ships as a Claude Code plugin, distributed from the `claude-mallet` marketplace this repository hosts (`.claude-plugin/marketplace.json`).

## Install

In Claude Code:

```
/plugin marketplace add dfsramos/claude-mallet
/plugin install mallet@claude-mallet
/mallet:setup
```

`/mallet:setup` registers the statusline and offers to turn on auto-update. Nothing else needs configuring. The plugin has no version to pin, so you track commits on the marketplace's default branch; [CHANGELOG.md](CHANGELOG.md) lists what each update changes.

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

## Documentation

- [Project Structure](docs/structure.md)
- [Directives](docs/directives.md)
- [Hooks](docs/hooks.md)
- [Skills](docs/skills.md)
