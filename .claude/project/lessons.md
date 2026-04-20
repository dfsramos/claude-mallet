# Lessons

Append after any user correction: what went wrong and the rule to prevent it.

<!-- Format:
## YYYY-MM-DD — <short title>
**What went wrong:** ...
**Rule:** ...
-->

## 2026-04-05 — Attempted to write session files despite documented prohibition
**What went wrong:** During wrap-up, tried to create `.claude/sessions/<id>.md` even though `.claude/project/CLAUDE.md` explicitly states "session wrap-ups are conversational only — no files are written to disk".
**Rule:** Always read `.claude/project/CLAUDE.md` before executing any skill. Project-level directives override skill instructions.
