# Augmentation Catalog

Tools `/mallet:discover` can recommend in step 3. Each entry states how to install it and the signals that justify or rule out a recommendation. Recommend an entry only when its signals are present in the project, and cite the specific signal in the report.

To add a tool, append an entry in the same shape under the matching layer. Keep `Recommend when` concrete enough to check against the codebase.

---

## MCP servers

Added to `.mcp.json` at the project root.

### Context7

- **Provides:** current, version-specific library documentation, queried live.
- **Install:** `npx -y @upstash/context7-mcp@latest`
- **Recommend when:** dependencies include fast-moving libraries, where version-specific docs matter.

---

## Skill packs

### Impeccable

- **Provides:** frontend UI and design commands.
- **Install:** `npx skills add pbakaus/impeccable`
- **Recommend when:** the project involves frontend UI or design work.

### CLI-Anything

- **Provides:** a registry of ~100+ pre-built `SKILL.md` harnesses that make desktop and server software agent-native.
- **Install:** the hub with `pip install cli-anything-hub`, then `cli-hub install <name>`; or one skill with `npx skills add HKUDS/CLI-Anything --skill <name>`.
- **Recommend when:** the project interacts with design, media, GIS, automation, or desktop software. Map detected software to a harness:

  | Detected software / dependency | Suggested harness |
  |---|---|
  | Blender, FreeCAD, 3MF files | `blender`, `freecad`, `3mf` |
  | GIMP, Krita, Inkscape | `gimp`, `krita`, `inkscape` |
  | Godot, Unreal Engine | `godot`, `unreal-insights` |
  | Obsidian, Zotero, Joplin | `obsidian`, `zotero`, `joplin` |
  | LibreOffice, Calibre | `libreoffice`, `calibre` |
  | n8n, Dify | `n8n`, `dify-workflow` |
  | QGIS, ArcGIS | `qgis`, `arcgis-pro` |

  Browse the full registry with `cli-hub list` or at https://hkuds.github.io/CLI-Anything/.

---

## Code intelligence plugins

Language server (LSP) plugins from Anthropic's official marketplace, `claude-plugins-official`. Each one gives Claude an `LSP` tool for symbol lookups (definitions, references) instead of text search, and reports type errors and missing imports after every edit. The plugin only names the server; the language server binary must be installed separately and on the `PATH` of the shell that starts `claude`. Reference: https://code.claude.com/docs/en/plugins/code-intelligence

- **Install:** first the binary, using the command in the plugin's README at `https://github.com/anthropics/claude-plugins-official/tree/main/plugins/<plugin>`; then `claude plugin install <plugin>@claude-plugins-official` from the shell (default scope `user`; `--scope project` enables it in the repo's `.claude/settings.json`, but each collaborator still runs the same install once). The plugin loads after `/reload-plugins` or in a new session.
- **Recommend when:** a language in the table below is in meaningful use (application code, not a stray script). Recommend one plugin per such language.
- **Skip when:** `claude plugin list` already shows the plugin, or the project is worked on only in cloud sessions, where Claude Code doesn't start plugin language servers.
- **Report:** for each recommendation, whether the binary is already on `PATH` (`command -v <binary>`). When it is, the install is a single command.

  | Language | Plugin | Binary |
  |---|---|---|
  | C/C++ | `clangd-lsp` | `clangd` |
  | C# | `csharp-lsp` | `csharp-ls` |
  | Go | `gopls-lsp` | `gopls` |
  | Java | `jdtls-lsp` | `jdtls` |
  | Kotlin | `kotlin-lsp` | `kotlin-lsp` |
  | Lua | `lua-lsp` | `lua-language-server` |
  | PHP | `php-lsp` | `intelephense` |
  | Python | `pyright-lsp` | `pyright-langserver` |
  | Ruby | `ruby-lsp` | `ruby-lsp` |
  | Rust | `rust-analyzer-lsp` | `rust-analyzer` |
  | Swift | `swift-lsp` | `sourcekit-lsp` |
  | TypeScript / JavaScript | `typescript-lsp` | `typescript-language-server` |

  For a language not listed, check the official marketplace for a newer plugin before concluding none exists.
