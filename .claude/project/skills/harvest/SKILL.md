---
name: harvest
description: Harvests project-specific skills from a target project into the ai-framework base, and checks for framework drift. Invokes when the user says "harvest", "run harvest", or "harvest <project-path>".
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---
# Harvest

Promote project-specific skills to the ai-framework base and reconcile framework drift in the target project.

This skill has three phases:
1. **Pull check** — ensure ai-framework is up to date before comparing anything
2. **Drift detection** — compare every `source/` file against the target's installed version
3. **Skill promotion** — lift selected project skills into the framework base

---

## 0. Resolve Target

If the user provided a target path in their invocation, use it. Otherwise ask:

```
AskUserQuestion: "Which project do you want to harvest? (absolute path)"
```

Expand `~` and resolve to an absolute path. Confirm the directory exists. Store as `TARGET`.

Locate the ai-framework repo root by reading the path of this skill file and walking up to the directory that contains `source/`. Store as `FRAMEWORK_ROOT`.

---

## 1. Pull Check

Run inside `FRAMEWORK_ROOT`:

```bash
git fetch --quiet
git status --short --branch
```

Inspect the output. If the local branch is behind the remote (output contains `behind`):

- Tell the user: "ai-framework is behind the remote. Pulling now..."
- Run `git pull --ff-only`
- If the pull fails (non-fast-forward or conflicts), stop and tell the user to resolve it manually before harvesting

If already up to date, note it and continue.

---

## 2. Drift Detection

Compare every file under `FRAMEWORK_ROOT/source/` against its counterpart in `TARGET`.

**For each source file:**

1. Derive the relative path (strip `source/` prefix)
2. Check whether the file exists in `TARGET/<relative>`
3. If it does not exist: flag as **missing**
4. If it does exist: run `diff --unified=3 TARGET/<relative> FRAMEWORK_ROOT/source/<relative>` and capture output
5. If diff is non-empty: flag as **outdated**

Collect all flagged files. If none are found, report "No drift detected." and skip to Phase 3.

**Present a drift report:**

```
Drift detected in <TARGET>:

  MISSING  .claude/hooks/session-start.sh
  OUTDATED CLAUDE.md
  OUTDATED .claude/skills/plan-feature/SKILL.md
```

For each outdated file, read both versions and produce a brief human-readable summary of what changed (e.g. "Added a new Git Workflow section", "Updated the allowed-tools list"). Do not dump raw diffs — synthesise.

Then ask the user:

```
AskUserQuestion: "Which drifted files do you want to update in <TARGET>?"
(multi-select, one option per flagged file, plus "Skip all")
```

For each file the user selects:
- Copy `FRAMEWORK_ROOT/source/<relative>` → `TARGET/<relative>`, creating parent directories as needed
- Log: `Updated: <relative>`

After applying updates, set hook permissions on any `.sh` files that were updated under `.claude/hooks/`.

---

## 3. Skill Promotion

Scan `TARGET/.claude/project/skills/` for skill directories (one level deep). If the directory does not exist or is empty, report "No project-specific skills found." and finish.

List the discovered skills. Ask the user which to promote:

```
AskUserQuestion: "Which project skills do you want to promote to the framework base?"
(multi-select)
```

If none selected, finish.

**For each selected skill:**

1. Source: `TARGET/.claude/project/skills/<skill>/`
2. Destination: `FRAMEWORK_ROOT/source/.claude/skills/<skill>/`

If the destination already exists:
- Read both `SKILL.md` files
- Summarise what differs (triggers, phases, tools)
- Ask: `[overwrite] [skip]`
- If skip: log and continue to next skill

If overwriting or new:
- Copy the entire skill directory to the destination
- Remove the skill directory from `TARGET/.claude/project/skills/`
- Log: `Promoted: <skill>`

---

## 4. Summary

Print a final summary:

```
── Harvest complete ──────────────────────────────────────
  Target:    <TARGET>

  Drift:
    Updated:  <list or "none">
    Skipped:  <list or "none">

  Skills promoted:  <list or "none">
  Skills skipped:   <list or "none">

  Reminder: re-run the install skill on the target to propagate
  any newly promoted base skills. Open this repo in Claude Code and say:

    install the framework into <TARGET>
─────────────────────────────────────────────────────────
```

Only show the install reminder if at least one skill was promoted.
