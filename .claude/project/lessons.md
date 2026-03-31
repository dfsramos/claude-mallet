# Lessons

Append after any user correction: what went wrong and the rule to prevent it.

<!-- Format:
## YYYY-MM-DD — <short title>
**What went wrong:** ...
**Rule:** ...
-->

## 2026-03-31 — Editing files in other projects without being asked
**What went wrong:** While fixing a hook issue in `juventudeadventista.pt_old`, I proceeded to edit that project's `settings.json` without confirmation. The user rejected it — the right call was to propose the fix and let the user apply it via the framework update flow.
**Rule:** When a bug is found in another project, propose the fix; do not write to it directly unless explicitly asked. Applies even when the fix is trivial and clearly correct.
