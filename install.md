# AI Framework — Remote Installation Instructions

Install the AI framework into the current working directory from a GitHub URL. This is a **source-of-truth install** — framework-managed files overwrite any local equivalents. `.claude/project/` is reset to a clean scaffold (any prior content is wiped). `.claude/settings.local.json` is preserved.

---

## 1. Resolve the Repo

The user provided a GitHub URL (`https://github.com/{owner}/{repo}`). Extract `owner` and `repo`.

---

## 2. Fetch the Latest Commit

Query the default branch and its HEAD commit via the GitHub API:

```bash
BRANCH=$(curl -sf "https://api.github.com/repos/{owner}/{repo}" | jq -r '.default_branch')
NEW_SHA=$(curl -sf "https://api.github.com/repos/{owner}/{repo}/commits/${BRANCH}" | jq -r '.sha')
```

---

## 3. Download and Extract

```bash
WORK=/tmp/claude-mallet-install
rm -rf "$WORK"
mkdir -p "$WORK"
curl -sfL "https://github.com/{owner}/{repo}/archive/${NEW_SHA}.tar.gz" -o "$WORK/tarball.tar.gz"
tar -xzf "$WORK/tarball.tar.gz" -C "$WORK" --strip-components=1
```

After extraction, `$WORK/.claude/` and `$WORK/CLAUDE.md` contain the framework payload. If either is missing, stop and report the download failure.

---

## 4. Install Framework Files

**Before proceeding, confirm the target directory.** Run `pwd` and ask the user to confirm the absolute path is the project they want to install into. The next commands delete and replace files in that directory — if the user is in the wrong place, stop and do not run anything below.

The `cp` commands below copy only framework-managed subtrees. `.claude/project/` is reset in step 5 — do not copy it here.

```bash
mkdir -p .claude
rm -rf .claude/agents .claude/hooks .claude/skills .claude/templates .claude/statusline.sh .claude/settings.json CLAUDE.md

cp -r "$WORK/.claude/agents" "$WORK/.claude/hooks" "$WORK/.claude/skills" "$WORK/.claude/templates" .claude/
cp "$WORK/.claude/statusline.sh" "$WORK/.claude/settings.json" .claude/
cp "$WORK/CLAUDE.md" ./CLAUDE.md
```

`.claude/settings.local.json` and `.claude/framework.json` are untouched.

---

## 5. Reset Project Scaffold

A fresh install must not inherit the source repo's own project files (lessons, skill backlog, feature plans, etc.). Wipe `.claude/project/` and recreate only the minimal scaffold:

```bash
rm -rf .claude/project
mkdir -p .claude/project/missions
```

`.claude/settings.local.json` and `.claude/framework.json` are untouched.

---

## 6. Restore Hook Permissions

```bash
chmod +x .claude/hooks/*.sh
```

---

## 7. Write Framework Metadata

Write `.claude/framework.json`:

```json
{
  "repo": "{owner}/{repo}",
  "version": "<NEW_SHA>",
  "installed_at": "<today as YYYY-MM-DD>"
}
```

---

## 8. Cleanup

```bash
rm -rf /tmp/claude-mallet-install
```

---

## 9. Detect Project Type and Suggest Skills

Scan the target for cues and offer up to 3 concrete skill suggestions:

- **Node/TypeScript** (`package.json`): `context7` MCP server; scripts worth capturing
- **Python** (`pyproject.toml`, `requirements.txt`): virtualenv/poetry workflow skills
- **Go** (`go.mod`): build/test patterns
- **CI config** (`.github/workflows/`, `.gitlab-ci.yml`): deploy skill
- **Database ORM** (Prisma, Drizzle, SQLAlchemy, etc.): migration skills

Keep suggestions brief. Do not create them automatically.

---

## 10. Summary

```
── Installation complete ────────────────────────────────────

  Target:    <current directory>
  Version:   <short sha (first 7 chars)>

  Next steps:
    1. Customise .claude/project/CLAUDE.md for this project (create if needed)
    2. Run /discover to scan the project for .claude/ setup opportunities
    3. [Context-specific suggestion from step 9, if any]

────────────────────────────────────────────────────────────
```
