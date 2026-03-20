---
name: install
description: Invoke when the user says "install", "install the framework", "install into [target]", or asks to set up the ai-framework in another project. Only valid when running inside the ai-framework repo. For remote installs (user provides a GitHub URL), follow install.md from the repo root instead.
---
# Framework Installation

Install the ai-framework into a target project directory, making intelligent decisions based on what already exists there.

---

## 1. Resolve the Target

If the user provided a path in their message, use it. Otherwise ask:

> "Which directory should I install the framework into?"

Verify the path exists and resolve it to an absolute path. If it does not exist, report the error and stop.

The `source/` directory in this repo (relative to the repo root) is the installation source. Confirm it exists before proceeding.

---

## 2. Inspect the Target

Read the target project to understand its current state. Do this in parallel:

- Check if `.claude/` exists at all (fresh install vs. upgrade)
- If upgrading: read the existing `CLAUDE.md` and compare it against `source/CLAUDE.md` — note any additions or customisations the user has made
- Read all existing skill files in `.claude/skills/` and `.claude/project/skills/` if present
- Check `.claude/project/CLAUDE.md` if it exists
- Detect the project type: look for `package.json`, `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, etc.
- Check if the target is a git repo (`.git/` present)
- Check the existing `.gitignore` for framework entries

---

## 3. Assess Conflicts

Identify files that would be overwritten and that appear to have been customised:

- `CLAUDE.md` with content beyond the base template
- Any skill files with local modifications
- `settings.json` with project-specific settings

For each conflict, note: file path, what the customisation is, and whether the incoming version would destroy it.

---

## 4. Report and Confirm

Present a clear pre-flight summary:

```
Target:  /path/to/project
Mode:    fresh install | upgrade (vX → current)

Files to install:   N
Conflicts detected: N

Conflicts:
  - .claude/CLAUDE.md — contains local customisations (N lines added)
  - [other files...]
```

If there are conflicts, ask:

> "These files have local customisations that would be overwritten. How should I handle them?"

Options:
1. **Overwrite all** — replace with framework versions (customisations lost)
2. **Skip conflicts** — install everything except conflicting files
3. **Review each** — decide file by file

If there are no conflicts, proceed without asking.

---

## 5. Install Files

Copy each file from `source/` to the target. For each file:

- If it is in the skip list (user chose option 2 or 3 and skipped it), skip it
- Otherwise copy it, preserving directory structure
- Log: `Installed:` for new files, `Overwritten:` for replaced files

Use the Write tool to write each file (Read it from `source/` first, then Write to target).

**Do not use Bash for file copying** — use Read + Write per file so each change is visible and reviewable.

---

## 6. Write Framework Metadata

Write `.claude/framework.json` in the target directory:

```json
{
  "repo": "{owner}/{repo}",
  "version": "<output of: git -C source rev-parse HEAD>",
  "installed_at": "<today's date as YYYY-MM-DD>"
}
```

Get the commit hash by running:

```bash
git rev-parse HEAD
```

from the root of this repo.

---

## 7. Create Runtime Directories

Ensure these directories exist at the target (create if missing):

- `.claude/sessions/`

---

## 8. Set Hook Permissions

For every `.sh` file under `.claude/hooks/` in the target, run `chmod +x` via Bash.

---

## 9. Update .gitignore

If the target is a git repo, ensure `.gitignore` contains:

```
.claude/sessions/*
```

Read the existing `.gitignore` first. Append only entries that are not already present.

---

## 10. Detect Project Type and Suggest Skills

Based on what you found in step 2, provide tailored recommendations:

- **Node/TypeScript project**: suggest `context7` MCP server, note `package.json` scripts worth capturing as skills
- **Python project**: suggest virtualenv/poetry workflow skills if detected
- **Go project**: suggest build/test workflow patterns
- **Any project with CI config** (`.github/workflows/`, `.gitlab-ci.yml`): suggest a deploy skill
- **Any project with a database** (Prisma, Drizzle, SQLAlchemy, etc.): suggest migration skills

List at most 3 high-value suggestions. Keep them concrete and brief.

---

## 11. Summary

Print a final summary:

```
── Installation complete ────────────────────────────────────

  Target:    /path/to/project
  Version:   <short hash (first 7 chars)>
  Installed: N file(s)
  Skipped:   N file(s) (conflicts preserved)

  Next steps:
    1. Open .claude/CLAUDE.md and customise it for this project
    2. Run 'claude' in the target directory to start a session
    3. [Context-specific suggestion from step 10, if any]

────────────────────────────────────────────────────────────
```

Offer a session wrap-up.
