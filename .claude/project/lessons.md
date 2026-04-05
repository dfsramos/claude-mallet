# Lessons

Append after any user correction: what went wrong and the rule to prevent it.

<!-- Format:
## YYYY-MM-DD — <short title>
**What went wrong:** ...
**Rule:** ...
-->

## 2026-04-05 — Attempted to write session files despite documented prohibition
**What went wrong:** During wrap-up, tried to create `.claude/sessions/<id>.md` even though `.claude/project/CLAUDE.md` explicitly states "session wrap-ups are conversational only — no files are written to `.claude/sessions/`".
**Rule:** Always read `.claude/project/CLAUDE.md` before executing any skill. Project-level directives override skill instructions.

## 2026-03-31 — Editing files in other projects without being asked
**What went wrong:** While fixing a hook issue in `juventudeadventista.pt_old`, I proceeded to edit that project's `settings.json` without confirmation. The user rejected it — the right call was to propose the fix and let the user apply it via the framework update flow.
**Rule:** When a bug is found in another project, propose the fix; do not write to it directly unless explicitly asked. Applies even when the fix is trivial and clearly correct.
