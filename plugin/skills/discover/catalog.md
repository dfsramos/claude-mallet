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

## Standalone tools

### Graphify

- **Provides:** a queryable knowledge graph of the codebase — god nodes, surprising connections, interactive visualisation. Requires Python.
- **Install:** `pip install graphify` or `uv add graphify`
- **Recommend when** 3 or more are true:
  - Large codebase — many source files spread across multiple modules, packages, or services
  - Polyglot — 3+ languages in meaningful use (e.g. TypeScript + Python + SQL + shell)
  - Mixed modalities — docs, PDFs, architectural diagrams, or research papers live alongside code
  - High interdependence — layered architecture, microservices, multiple databases, or complex import graph
  - Team context — multiple contributors; a shared `graphify-out/graph.json` committed to git has compounding value
- **Skip when** any of these apply:
  - Small project (fewer than ~20 meaningful source files)
  - Primarily configuration or scripts with minimal application logic
  - Logic concentrated in one or two files — the graph won't reveal non-obvious connections
