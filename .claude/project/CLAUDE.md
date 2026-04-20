# Framework-Specific Conventions

## Framework vs Project Content

Everything under `.claude/project/` and `.claude/features/` is **this repo's own content** — it is never installed into target projects. The install and update flows skip both paths explicitly.

All other `.claude/` content (`hooks/`, `skills/`, `templates/`, `statusline.sh`, `settings.json`) plus the root `CLAUDE.md` is **framework payload** — it ships to every target.

When adding a new skill:
- **Framework skill** (should ship to target projects): `.claude/skills/<name>/`
- **Project skill** (only this repo): `.claude/project/skills/<name>/`

## Docs Parity

Any change to a skill or hook must update the corresponding section in `docs/`:
- Skill changes → `docs/skills.md`
- Hook changes → `docs/hooks.md`
- Structural changes → `docs/structure.md`
- Directive changes → `docs/directives.md`

## Session Records

Session wrap-ups are conversational only — no files are written to disk.
