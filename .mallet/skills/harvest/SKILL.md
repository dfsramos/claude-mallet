---
name: harvest
description: Invoke when the user says "harvest", "run harvest", or "harvest <project-path>" inside the claude-mallet repo.
---
# Harvest

Review a target project for improvements worth pulling back into the framework base. Runs inside the claude-mallet repo only.

Two phases:

1. **Project skills** — lift selected project-specific skills from the target into the framework
2. **Overrides** — surface skill overrides present in the target for review; never auto-promote

Target projects hold no framework files — Mallet reaches them as the `mallet` plugin — so there is no drift to reconcile. A project that needs different behaviour uses (a) a project skill, (b) an override, or (c) a PR to the framework.

---

## 0. Resolve Target

If the user provided a target path, use it. Otherwise ask:

```
AskUserQuestion: "Which project do you want to harvest? (absolute path)"
```

Expand `~`, resolve to absolute, confirm the directory exists. Store as `TARGET`.

`FRAMEWORK_ROOT` is the current working directory (this repo).

---

## 1. Pull Check

Run inside `FRAMEWORK_ROOT`:

```bash
git fetch --quiet
git status --short --branch
```

If the local branch is behind the remote, tell the user and run `git pull --ff-only`. If the pull fails, stop and ask the user to resolve manually. If already up to date, continue silently.

---

## 2. Project Skills

Scan `TARGET/.mallet/skills/` for skill directories (one level deep). If empty or absent, note "No project skills found." and continue to Phase 3.

List discovered skills with a one-line summary of each (read the `description` field). Ask:

```
AskUserQuestion: "Which project skills do you want to promote to the framework base?"
(multi-select; one option per skill plus "Skip all")
```

**For each selected skill:**

- Source: `TARGET/.mallet/skills/<skill>/`
- Destination: `FRAMEWORK_ROOT/plugin/skills/<skill>/`

If the destination already exists:
- Read both `SKILL.md` files
- Summarise what differs (triggers, phases, tools)
- Ask: `[overwrite] [skip]`
- If skip: log and continue

If overwriting or new:
- Copy the entire skill directory to the destination
- Adapt it to the plugin layout:
  - it will be invoked as `/mallet:<skill>`; the `name` field must equal the directory name
  - the `description` states trigger conditions only
  - paths to files bundled with the skill use `${CLAUDE_SKILL_DIR}`; paths into the project (`.mallet/...`) stay relative
  - nothing project-specific remains (hostnames, repo names, credentials) — generalise or stop and ask
- Run `bash tests/run.sh`; `test-15-plugin.sh` checks skill structure
- Ask before removing the original from `TARGET/.mallet/skills/`: the plugin copy replaces it, but deleting it is the user's call. Remove it only on an explicit yes.
- Log: `Promoted: <skill>`

---

## 3. Overrides

Scan `TARGET/.mallet/overrides/` for `*.md` files. If empty or absent, note "No overrides found." and continue to Phase 4.

For each override file:
1. Read the override
2. Read the matching base skill at `FRAMEWORK_ROOT/plugin/skills/<skill-name>/SKILL.md`
3. Summarise what the override changes (one or two lines)

Present the list with summaries, then ask:

```
AskUserQuestion: "Do any of these overrides reveal gaps worth fixing in the base skill?"
(per override: [fold into base skill] [leave as project-specific] [skip])
```

For each "fold" selection:
- Propose a concrete edit to the base skill that incorporates the override's intent (generalised, not project-specific)
- Apply the edit only after user confirmation
- Remove the override file and its entry from `TARGET/.mallet/conventions.md` Skill Overrides list
- Log: `Folded: <skill-name>`

For "leave" or "skip": log and continue.

---

## 4. Summary

```
── Harvest complete ──────────────────────────────────────
  Target:             <TARGET>

  Skills promoted:    <list or "none">
  Skills skipped:     <list or "none">

  Overrides folded:   <list or "none">
  Overrides retained: <list or "none">
─────────────────────────────────────────────────────────
```

If anything was promoted or folded:
- update `docs/skills.md` and the README skills table (Docs Parity in `.mallet/conventions.md`)
- remind the user that the change reaches machines only after it is pushed and the plugin updates there (auto-update, or `/plugin marketplace update claude-mallet`)
- if an original project skill was kept in `TARGET`, note that it duplicates `/mallet:<skill>` and can be removed once the plugin version is confirmed working
