---
name: self-assessment
description: Invoke when the user asks for a self-assessment, critical assessment, health check, or audit of Mallet itself inside the claude-mallet repo.
---
# Self-Assessment

Critically review the Mallet plugin and this repo, verify every finding that drives a recommendation, rank the results, and fix them in groups the user approves. Runs inside the claude-mallet repo only.

Read `.mallet/conventions.md` first: Git Workflow Override (commit to `master`), Hook Authoring, Docs Parity, and Changelog all apply to the fixes.

---

## 1. Baseline

```bash
bash tests/run.sh
git status --short --branch
```

Record the suite count and check count. A failing suite is the first finding, not something to work around.

---

## 2. Fan Out Four Reviewers

Dispatch four read-only `general-purpose` agents in one message. Each reads `.mallet/conventions.md` first, edits nothing, and returns a ranked list: severity (high, medium, low), `file:line` evidence, and a one-line fix, under about 700 words.

| Area | Files | Look for |
|---|---|---|
| Persona and directives | `plugin/persona/PERSONA.md`, `plugin/hooks/persona.sh`, `docs/directives.md` | Contradictions between directives and with what skills do; drift from `docs/directives.md`; references to hooks, files, or skills that do not exist; size against the `test-15` cap; directives that duplicate Claude Code built-ins or a hook |
| Skills and agents | `plugin/skills/`, `plugin/agents/`, `plugin/workflows/`, `docs/skills.md`, `.mallet/skills/`, `.mallet/skill-backlog.md` | Descriptions that summarise instead of stating triggers, or overlap; triggers that cannot fire (`disable-model-invocation`); broken paths and names; skills and workflows sharing a name; drift from `docs/skills.md`; overlap with built-in Claude Code features |
| Executable code | `plugin/hooks/`, `plugin/statusline/`, `plugin/workflows/`, `.claude/*.sh`, `tests/`, `docs/hooks.md`, `docs/structure.md` | Correctness, bash 3.2 and BSD portability, output channel per hook event, output over 10,000 characters, stdin handling, timeouts, per-prompt cost, test gaps, docs drift |
| Repo health | `README.md`, `install.md`, `CHANGELOG.md`, `.mallet/features/`, `.mallet/discovery-*.md`, git history and branches | Stale plans and discovery items, transitional code against its retirement condition in `docs/structure.md`, changelog gaps for user-visible commits, README accuracy, churn hotspots |

---

## 3. Verify Before Reporting

Reviewers are wrong often enough to matter. Before a finding goes in the report, check each high-severity finding and any finding that would drive a change:

- Code claims: read the cited lines.
- Hook, plugin, or skill semantics: fetch the Claude Code docs page (`code.claude.com/docs/en/hooks`, `/plugins-reference`) and quote it. Ask the fetch for the relevant section only.
- Portability claims: reproduce in `docker run --rm bash:3.2` (install `jq git coreutils` with `apk`).
- Git remote state: `git ls-remote --heads origin`, never `git branch -a` alone, since remote-tracking refs go stale.

Drop findings that fail verification, and mark any you could not check as **unverified**.

---

## 4. Report

One ranked report: High, Medium, Low, each a table of finding, evidence, and fix. Close with the fixes as numbered groups in a suggested order. The order runs from mechanical bug fixes, to changes that need a docs check, to persona text, to decisions that belong to the user, such as versioning, retiring code, or deleting branches. Ask which group to start with.

---

## 5. Fix Group by Group

For each group the user starts:

1. **Edit.** For persona or other directive text, draft the change and show it before committing. Ask the user about anything that changes behaviour they may have chosen on purpose.
2. **Test the fix.** Add a test that fails against the previous code and passes now. Prove the failure: copy `plugin/` and `tests/` to a scratch directory, restore the `HEAD` version of the changed file with `git show HEAD:<path>`, and run the suite there.
3. **Portability.** For a change under `plugin/hooks/` or `plugin/statusline/`, also run the affected suites in the `bash:3.2` image.
4. **Docs and changelog.** Update the `docs/` file required by Docs Parity. If users will notice the change, add a `CHANGELOG.md` entry under today's date.
5. **Full suite.** Run `bash tests/run.sh`.
6. **Independent review.** Dispatch `mallet:code-reviewer` with the intent of the change and what to probe. Apply blocking issues and re-run the suite; then decide each non-blocking note on its merits.
7. **Commit.** Commit to `master` and push. Report what changed, what the review caught, and the next group.

Destructive steps, such as deleting branches or files, are shown first and wait for explicit confirmation. Check what would be lost before asking.

---

## 6. Close Out

Summarise the commits, which findings turned out to be wrong, and what is left for the user. Then offer `/mallet:reviewing-sessions`.
