# Framework-Specific Conventions

## Two-Location Rule

Every new skill added to `.claude/skills/` must be mirrored to `source/.claude/skills/` so it is included in future installs and updates — **except** framework-only skills:

| Skill | Location | Reason |
|-------|----------|--------|
| `install` | `.claude/skills/` only | Requires the `source/` directory; not useful in target projects |
| `harvest` | `.claude/project/skills/` only | Framework maintenance; never distributed |
| `update` | `source/.claude/skills/` only | Requires `framework.json`; not useful in the framework repo itself |

## Docs Parity

Any change to a skill or hook must update the corresponding section in `docs/`. Specifically:
- Skill changes → `docs/skills.md`
- Hook changes → `docs/hooks.md`
- Structural changes → `docs/structure.md`
- Directive changes → `docs/directives.md`

## Session Records

Session wrap-ups are conversational only — no files are written to `.claude/sessions/`. The directory exists solely for runtime state (e.g., `.current`).
