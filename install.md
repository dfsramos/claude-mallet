# AI Framework — Remote Installation Instructions

You are installing the AI framework into the current working directory. Follow these steps precisely.

---

## 1. Derive the Repo Slug

The user provided a GitHub URL. Extract `owner` and `repo` from it.

Pattern: `https://github.com/{owner}/{repo}`

From this point forward, refer to the repo as `{owner}/{repo}` (e.g. `dfsramos/ai-framework`).

---

## 2. Clone to a Temporary Directory

Run the following via Bash:

```bash
TMPDIR="/tmp/ai-framework-install-$(date +%s)"
git clone --depth=1 "https://github.com/{owner}/{repo}.git" "$TMPDIR"
```

If the clone fails, report the error and stop. Do not proceed.

Capture the commit hash of the clone:

```bash
cd "$TMPDIR" && git rev-parse HEAD
```

Store it — you will need it in step 5.

---

## 3. Inspect the Target (Current Directory)

Do this in parallel:

- Check if `.claude/` exists (fresh install vs. upgrade)
- If upgrading: read the existing `CLAUDE.md` and compare against `$TMPDIR/source/CLAUDE.md` — note any local customisations
- Read all existing skill files in `.claude/skills/` and `.claude/project/skills/` if present
- Read `.claude/project/CLAUDE.md` if present
- Detect project type: look for `package.json`, `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, etc.
- Check if the directory is a git repo (`.git/` present)
- Read `.gitignore` if it exists

---

## 4. Assess Conflicts

Identify files that would be overwritten and that appear to have been customised:

- `CLAUDE.md` with content beyond the base template
- Any skill files with local modifications
- `.claude/settings.json` with project-specific settings

For each conflict, note: file path, what the customisation is, and whether the incoming version would destroy it.

---

## 5. Report and Confirm

Present a pre-flight summary:

```
Target:  <current directory>
Mode:    fresh install | upgrade

Files to install:   N
Conflicts detected: N

Conflicts:
  - CLAUDE.md — contains local customisations (N lines added)
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

## 6. Install Files

Use the `find` command to list all files under `$TMPDIR/source/`:

```bash
find "$TMPDIR/source" -type f
```

For each file:

- Derive the relative path by stripping the `$TMPDIR/source/` prefix
- If it is in the skip list, skip it
- Read it from `$TMPDIR/source/<relative-path>` using the Read tool
- Write it to `<current-directory>/<relative-path>` using the Write tool
- Log: `Installed:` for new files, `Overwritten:` for replaced files

Do not use Bash for file copying — use Read + Write per file so each change is visible and reviewable.

---

## 7. Write Framework Metadata

Write `.claude/framework.json` in the current directory:

```json
{
  "repo": "{owner}/{repo}",
  "version": "<full commit hash from step 2>",
  "installed_at": "<today's date as YYYY-MM-DD>"
}
```

---

## 8. Create Runtime Directories

Ensure `.claude/sessions/` exists:

```bash
mkdir -p ".claude/sessions"
```

---

## 9. Set Hook Permissions

For every `.sh` file under `.claude/hooks/`, run:

```bash
chmod +x <file>
```

---

## 10. Update .gitignore

If the target is a git repo, ensure `.gitignore` contains:

```
.claude/sessions/*
```

Read the existing `.gitignore` first. Append only if not already present.

---

## 11. Remove Temporary Directory

```bash
rm -rf "$TMPDIR"
```

---

## 12. Detect Project Type and Suggest Skills

Based on what you found in step 3, provide tailored recommendations:

- **Node/TypeScript**: suggest `context7` MCP server, note `package.json` scripts worth capturing as skills
- **Python**: suggest virtualenv/poetry workflow skills if detected
- **Go**: suggest build/test workflow patterns
- **CI config present** (`.github/workflows/`, `.gitlab-ci.yml`): suggest a deploy skill
- **Database ORM detected** (Prisma, Drizzle, SQLAlchemy, etc.): suggest migration skills

List at most 3 high-value suggestions. Keep them concrete and brief.

---

## 13. Summary

Print a final summary:

```
── Installation complete ────────────────────────────────────

  Target:    <current directory>
  Version:   <short hash (first 7 chars)>
  Installed: N file(s)
  Skipped:   N file(s) (conflicts preserved)

  Next steps:
    1. Open CLAUDE.md and customise it for this project
    2. Run 'claude' in this directory to start a session
    3. [Context-specific suggestion from step 12, if any]

────────────────────────────────────────────────────────────
```
