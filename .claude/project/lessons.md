# Lessons

Append after any user correction: what went wrong and the rule to prevent it.

<!-- Format:
## YYYY-MM-DD — <short title>
**What went wrong:** ...
**Rule:** ...
-->

## 2026-04-16 — Used Write instead of Edit when the file already existed
**What went wrong:** When simplifying `session-start.sh` in both `source/` and `.claude/`, used the Write tool for a full rewrite even though the files already existed. CLAUDE.md explicitly states "Always prefer Edit over Write. Write is only for creating files that do not yet exist."
**Rule:** Before using Write, check whether the target file already exists. If it does, use Edit — even for near-complete rewrites. Write is only for genuinely new files.

## 2026-04-06 — Shell variable declarations in Bash commands trigger permission prompts
**What went wrong:** The update skill used `TMPDIR="..."`, `BASE=...`, and `files=(...)` in bash commands. Claude Code's permission system cannot evaluate commands that start with variable assignments or contain array declarations — it prompts the user instead of auto-allowing them.
**Rule:** Never write bash commands in skills (or anywhere) that begin with variable assignments or use shell arrays. Use literal paths throughout. Replace `TMPDIR="..."` patterns with a fixed literal path like `/tmp/ai-framework-update`. Use `diff -rq <path1> <path2>` instead of loop scripts for bulk comparisons.

## 2026-04-05 — Attempted to write session files despite documented prohibition
**What went wrong:** During wrap-up, tried to create `.claude/sessions/<id>.md` even though `.claude/project/CLAUDE.md` explicitly states "session wrap-ups are conversational only — no files are written to `.claude/sessions/`".
**Rule:** Always read `.claude/project/CLAUDE.md` before executing any skill. Project-level directives override skill instructions.

## 2026-03-31 — Editing files in other projects without being asked
**What went wrong:** While fixing a hook issue in `juventudeadventista.pt_old`, I proceeded to edit that project's `settings.json` without confirmation. The user rejected it — the right call was to propose the fix and let the user apply it via the framework update flow.
**Rule:** When a bug is found in another project, propose the fix; do not write to it directly unless explicitly asked. Applies even when the fix is trivial and clearly correct.
