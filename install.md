# Claude Mallet — Installation Instructions

Install Claude Mallet into `~/.claude/` from a GitHub URL. **This is a machine-wide install**, not a per-project one — the directives, skills, agents, hooks, templates, and statusline apply in every project on this machine.

Nothing is written into any repository. A project only ever gains a `.mallet/` directory, and only when Mallet has something to store there.

## What this touches

| Path | Treatment |
|---|---|
| `~/.claude/skills/*`, `agents/*`, `templates/*`, `hooks/*` | installed **per entry** |
| `~/.claude/statusline.sh`, `~/.claude/CLAUDE.md` | installed (existing `CLAUDE.md` backed up first) |
| `~/.claude/settings.json` | **merged**, never replaced |
| `~/.claude/framework.json` | written, including a `manifest` |
| Any existing entry under `~/.claude/skills\|agents\|templates\|hooks` not in the payload | left alone |

Two rules, both load-bearing:

- **`~/.claude/skills`, `agents`, `templates`, and `hooks` are never removed wholesale.** They may already hold user-authored entries. Only individual payload entries are replaced.
- **`~/.claude/settings.json` is never overwritten.** It holds `model`, `effortLevel`, `enabledPlugins`, and the user's own hooks.

---

## 1. Resolve the repo

The user provided a GitHub URL (`https://github.com/{owner}/{repo}`). Extract `owner` and `repo`.

---

## 2. Fetch the latest commit

```bash
BRANCH=$(curl -sf "https://api.github.com/repos/{owner}/{repo}" | jq -r '.default_branch')
NEW_SHA=$(curl -sf "https://api.github.com/repos/{owner}/{repo}/commits/${BRANCH}" | jq -r '.sha')
```

If either call fails, stop and report. Do not continue on a failed lookup.

---

## 3. Download and extract

```bash
WORK=/tmp/claude-mallet-install
rm -rf "$WORK"; mkdir -p "$WORK"
curl -sfL "https://github.com/{owner}/{repo}/archive/${NEW_SHA}.tar.gz" -o "$WORK/tarball.tar.gz"
tar -xzf "$WORK/tarball.tar.gz" -C "$WORK" --strip-components=1
```

If `$WORK/.claude/` or `$WORK/CLAUDE.md` is missing, stop and report the download failure.

---

## 4. Confirm the target

Tell the user plainly, and wait for explicit confirmation:

> Mallet will be installed to `~/.claude/`. This is machine-wide — the persona and directives will apply in **every** project you open, including ones unrelated to this install. Existing personal config in `~/.claude/settings.json` is merged, not replaced, and a backup is taken first.

There is no `pwd` to confirm; the current directory is irrelevant to a user-level install. If the user expected a per-project install, explain that per-project mode no longer exists and that project-specific content belongs in that project's `.mallet/conventions.md`.

---

## 5. Back up existing user config

```bash
tar -czf "$HOME/.claude/mallet-preinstall-backup-$(date +%Y%m%d%H%M%S).tar.gz" \
  -C "$HOME/.claude" settings.json CLAUDE.md skills agents templates hooks statusline.sh framework.json 2>/dev/null
```

Missing members are fine — this succeeds on a machine with no prior `~/.claude/`. Report the path.

---

## 6. Handle an existing `~/.claude/CLAUDE.md`

If the file exists and differs from `$WORK/CLAUDE.md`, it may hold the user's own directives:

```bash
cp "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.pre-mallet-$(date +%Y%m%d)"
```

Tell the user the backup path, and that anything project-specific in it belongs in that project's `.mallet/conventions.md` rather than at user level. **Wait for confirmation before continuing** — this replaces a file that may be hand-written.

If the file does not exist, or is already identical to the payload, skip this step silently.

---

## 7. Install the payload

```bash
bash "$WORK/.claude/install-payload.sh" --from "$WORK" --repo "{owner}/{repo}" --sha "$NEW_SHA"
```

This installs each entry individually, reconciles any previous `manifest` (removing only what a prior Mallet release shipped and this one does not), restores executable bits on the hooks and statusline, and writes `~/.claude/framework.json` with a fresh manifest.

Relay its `removed:` and `preserved:` lines verbatim. The `preserved:` list is how the user confirms their own skills and agents survived.

---

## 8. Merge settings

```bash
bash "$WORK/.claude/merge-settings.sh" "$WORK/.claude/settings.fragment.json"
```

This registers the four base hooks and the statusline in `~/.claude/settings.json`, leaving every other key intact. It backs the file up first and refuses to run against a corrupt one.

The three opt-in hooks (`typecheck`, `push-confirm`, `explore-redirect`) are deliberately **not** registered here — they are per-project choices. Point the user at the `hooks-setup` skill to enable them in a specific project.

---

## 9. Clean up legacy per-project installs

Older Mallet versions installed into each repo. Find what is still out there:

```bash
bash "$HOME/.claude/skills/migrate/detect.sh"
```

- **Nothing found:** say so in one line and continue.
- **Legacy installs found:** present the table and offer to migrate them now via the `migrate` skill. That skill moves each repo's state into `.mallet/`, removes only untracked payload, leaves every tracked file alone, and takes a backup per repo before touching anything.

Do not migrate without confirmation. If the user defers, note that `session-start.sh` will offer again the next time they open one of those repos.

---

## 10. Ask the VCS question

Ask how `.mallet/` should be treated, and apply only what the user picks. Mallet has no default here and must not invent one:

| Answer | Action |
|---|---|
| Ignore on this machine | append `.mallet/` to `git config --global core.excludesFile`, defaulting to `~/.config/git/ignore` when unset — git reads that path automatically. Check for an existing entry first. |
| Ignore in specific repos | append `.mallet/` to each `<repo>/.git/info/exclude` |
| Commit it | write nothing. Mention `~/.claude/templates/mallet-gitignore` as a template they can copy in by hand. |
| Decide later | write nothing |

Never edit a repo's tracked `.gitignore`.

---

## 11. Cleanup

```bash
rm -rf /tmp/claude-mallet-install
```

---

## 12. Detect project type and suggest skills

If the current directory happens to be a project, scan for cues and offer up to 3 concrete skill suggestions:

- **Node/TypeScript** (`package.json`): `context7` MCP server; scripts worth capturing
- **Python** (`pyproject.toml`, `requirements.txt`): virtualenv/poetry workflow skills
- **Go** (`go.mod`): build/test patterns
- **CI config** (`.github/workflows/`, `.gitlab-ci.yml`): deploy skill
- **Database ORM** (Prisma, Drizzle, SQLAlchemy, etc.): migration skills

Keep suggestions brief. Do not create them automatically. Skip this step entirely if the current directory is not a project.

---

## 13. Summary

```
── Installation complete ────────────────────────────────────

  Installed:  ~/.claude/  (machine-wide)
  Version:    <short sha (first 7 chars)>
  Preserved:  <user-authored entries left untouched, or none>
  Backup:     <path>
  Migrated:   <n legacy per-project installs, or none found>
  Ignore:     <VCS choice applied, or deferred>

  Next steps:
    1. Add project-specific conventions to <project>/.mallet/conventions.md
    2. Run /discover in a project to scan it for setup opportunities
    3. Run /hooks-setup in a project to enable the opt-in hooks
    4. [Context-specific suggestion from step 12, if any]

────────────────────────────────────────────────────────────
```

If any step failed, say which and stop. Do not report a partial install as complete.
