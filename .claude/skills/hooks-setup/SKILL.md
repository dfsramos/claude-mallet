---
name: hooks-setup
description: Invoke when the user runs /hooks-setup, asks to "set up hooks", "enable typecheck", or wants to activate optional hook scripts in the current project.
---
# Hooks Setup

Activates optional hook scripts in the current project. Run from the target project root.

---

## 1. Check what is already registered

Read `.claude/settings.json`. For each optional hook, check whether its script filename already appears in any hook command string:
- `typecheck.sh` present → already registered

Report the current state.

---

## 2. Detect project stack

Check the following indicators:

| Stack | Indicator |
|-------|-----------|
| TypeScript | `tsconfig.json` exists, or `package.json` contains `"typescript"` under `dependencies` or `devDependencies` |
| PHP | `vendor/bin/phpstan` exists |

Report what was detected.

---

## 3. Present available hooks

For each optional hook not yet registered, describe it and ask the user which to enable:

**typecheck** _(PostToolUse on Edit)_
Runs the type-checker after every file edit and surfaces errors directly in context. Requires TypeScript or PHP project (detected above). Skipped if neither stack is detected.

To confirm before `git push`, use a permission rule instead of a hook: add `"Bash(git push *)"` to `permissions.ask` in settings.

If typecheck is already registered, report that and stop. Otherwise ask whether to enable it.

---

## 4. Register selected hooks

For each hook the user selected:

1. Verify `~/.claude/hooks/<name>.sh` exists. Hook scripts ship with the user-level install; if missing, skip it and report which file is absent.
2. Read the **project's** `.claude/settings.json` fresh. Opt-in hooks register per project — the script is global, the choice is local.
3. Check again whether the script filename already appears in any command string — if yes, skip (idempotent).
4. Determine the event and matcher:
   - `typecheck.sh` → event `PostToolUse`, matcher `Edit`
5. If the event key does not exist in `hooks`, add it as an empty array first.
6. Append this object to the event array:
   ```json
   {
     "matcher": "<matcher>",
     "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/<name>.sh\"" }]
   }
   ```
7. Write the change using **Edit, not Write**.

---

## 5. Confirm

Report:
- Which hooks were registered
- Which were skipped and why (already present / script missing / stack not detected)
